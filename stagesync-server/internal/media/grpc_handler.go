package media

import (
	"context"
	"errors"
	"io"
	"log"
	"path/filepath"
	"sync"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "stagesync-server/gen/go/stagesync/v1"
)

const chunkSize = 64 * 1024 // 64 KiB pro gRPC-Chunk

// GRPCHandler implementiert pb.MediaServiceServer.
type GRPCHandler struct {
	pb.UnimplementedMediaServiceServer
	store *Store
	cache *Cache

	subsMu sync.Mutex
	subs   map[chan struct{}]struct{} // Signalkanal: Store hat sich geändert
}

// NewGRPCHandler erzeugt einen MediaService-Handler und startet
// den Store-Beobachter für WatchManifest-Benachrichtigungen.
func NewGRPCHandler(store *Store, cache *Cache) *GRPCHandler {
	h := &GRPCHandler{
		store: store,
		cache: cache,
		subs:  make(map[chan struct{}]struct{}),
	}
	go h.watchStore()
	return h
}

// watchStore: Store-Änderungen → alle WatchManifest-Subscriber benachrichtigen.
func (h *GRPCHandler) watchStore() {
	storeCh, unsub := h.store.Subscribe()
	defer unsub()
	for range storeCh {
		h.subsMu.Lock()
		for ch := range h.subs {
			select {
			case ch <- struct{}{}:
			default: // Subscriber hängt nach; Signal verwerfen — nächstes kommt
			}
		}
		h.subsMu.Unlock()
	}
}

func (h *GRPCHandler) subscribeChanges() (ch chan struct{}, unsub func()) {
	ch = make(chan struct{}, 4)
	h.subsMu.Lock()
	h.subs[ch] = struct{}{}
	h.subsMu.Unlock()
	return ch, func() {
		h.subsMu.Lock()
		delete(h.subs, ch)
		h.subsMu.Unlock()
	}
}

// ── StreamFile ────────────────────────────────────────────────────────────────

func (h *GRPCHandler) StreamFile(req *pb.StreamFileRequest, stream pb.MediaService_StreamFileServer) error {
	if req.AssetId == "" && req.Name == "" {
		return status.Error(codes.InvalidArgument, "asset_id oder name erforderlich")
	}

	name, data, err := h.resolveAndLoad(req.AssetId, req.Name)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return status.Errorf(codes.NotFound, "asset nicht gefunden: asset_id=%q name=%q", req.AssetId, req.Name)
		}
		return status.Errorf(codes.Internal, "laden fehlgeschlagen: %v", err)
	}

	total := int64(len(data))
	offset := req.Offset
	if offset < 0 || offset > total {
		return status.Errorf(codes.InvalidArgument, "ungültiger offset %d (size %d)", offset, total)
	}

	log.Printf("[media/grpc] StreamFile %s offset=%d total=%d", name, offset, total)

	for offset < total {
		end := offset + chunkSize
		if end > total {
			end = total
		}
		if err := stream.Send(&pb.FileChunk{
			Data:       data[offset:end],
			Offset:     offset,
			TotalBytes: total,
		}); err != nil {
			return err
		}
		offset = end
	}
	return nil
}

// resolveAndLoad lädt Dateidaten aus dem RAM-Cache (bevorzugt) oder von Disk.
// Disk-Treffer werden sofort in den Cache geschrieben.
func (h *GRPCHandler) resolveAndLoad(assetID, name string) (resolvedName string, data []byte, err error) {
	// 1. Cache per asset_id
	if assetID != "" {
		if d, ok := h.cache.Get(assetID); ok {
			n := h.cache.nameForID(assetID)
			if n == "" {
				n = assetID
			}
			return n, d, nil
		}
	}
	// 2. Cache per name
	if name != "" {
		if d, ok := h.cache.GetByName(name); ok {
			return name, d, nil
		}
	}

	// 3. Disk
	var absPath string
	if assetID != "" {
		absPath, err = h.store.FilePathBySHA256(assetID)
		if err != nil && name != "" {
			absPath = h.store.FilePath(name)
			err = nil
		}
	} else {
		absPath = h.store.FilePath(name)
	}
	if err != nil {
		return "", nil, err
	}

	data, err = h.store.ReadAll(absPath)
	if err != nil {
		return "", nil, ErrNotFound
	}
	resolvedName = SafeName(filepath.Base(absPath))

	if info, statErr := h.store.Stat(resolvedName); statErr == nil {
		h.cache.Put(info.SHA256, resolvedName, data)
	} else if assetID != "" {
		h.cache.Put(assetID, resolvedName, data)
	}
	return resolvedName, data, nil
}

// ── UploadFile ────────────────────────────────────────────────────────────────

func (h *GRPCHandler) UploadFile(stream pb.MediaService_UploadFileServer) error {
	// Erstes Paket muss UploadMeta sein
	first, err := stream.Recv()
	if err != nil {
		return status.Errorf(codes.InvalidArgument, "erstes Paket fehlt: %v", err)
	}
	meta, ok := first.Payload.(*pb.UploadChunk_Meta)
	if !ok {
		return status.Error(codes.InvalidArgument, "erstes Paket muss UploadMeta sein")
	}
	filename := SafeName(meta.Meta.Filename)
	if !IsAudioName(filename) {
		return status.Errorf(codes.InvalidArgument, "nicht unterstütztes Audioformat: %s", filename)
	}

	// Pipe: Chunk-Empfang → store.Save (streaming, kein kompletter Buffer nötig)
	pr, pw := io.Pipe()
	type saveResult struct {
		info FileInfo
		err  error
	}
	resultCh := make(chan saveResult, 1)

	go func() {
		info, err := h.store.Save(filename, pr)
		resultCh <- saveResult{info, err}
	}()

	var pipeErr error
	for {
		msg, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			_ = pw.CloseWithError(err)
			<-resultCh
			return status.Errorf(codes.Internal, "empfang fehlgeschlagen: %v", err)
		}
		chunk, ok := msg.Payload.(*pb.UploadChunk_Data)
		if !ok {
			continue
		}
		if _, pipeErr = pw.Write(chunk.Data); pipeErr != nil {
			break
		}
	}
	if pipeErr != nil {
		_ = pw.CloseWithError(pipeErr)
	} else {
		_ = pw.Close()
	}

	res := <-resultCh
	if res.err != nil {
		return status.Errorf(codes.Internal, "speichern fehlgeschlagen: %v", res.err)
	}

	h.cache.EvictByName(filename)
	log.Printf("[media/grpc] UploadFile %s (%d B, sha=%s)", res.info.Name, res.info.SizeBytes, res.info.SHA256[:8])

	return stream.SendAndClose(&pb.UploadResponse{
		AssetId:   res.info.SHA256,
		Name:      res.info.Name,
		SizeBytes: res.info.SizeBytes,
		Audio:     audioInfoToProto(res.info.Audio),
	})
}

// ── DeleteFile ────────────────────────────────────────────────────────────────

func (h *GRPCHandler) DeleteFile(_ context.Context, req *pb.DeleteFileRequest) (*pb.DeleteFileResponse, error) {
	if req.Name == "" {
		return nil, status.Error(codes.InvalidArgument, "name erforderlich")
	}
	// Cache invalidieren bevor die Datei gelöscht wird (Stat danach schlägt fehl)
	if info, err := h.store.Stat(req.Name); err == nil {
		h.cache.Evict(info.SHA256)
	}
	if err := h.store.Delete(req.Name); err != nil {
		if errors.Is(err, ErrNotFound) {
			return nil, status.Errorf(codes.NotFound, "nicht gefunden: %s", req.Name)
		}
		return nil, status.Errorf(codes.Internal, "löschen fehlgeschlagen: %v", err)
	}
	log.Printf("[media/grpc] DeleteFile %s", SafeName(req.Name))
	return &pb.DeleteFileResponse{Success: true}, nil
}

// ── WatchManifest ─────────────────────────────────────────────────────────────

func (h *GRPCHandler) WatchManifest(req *pb.WatchManifestRequest, stream pb.MediaService_WatchManifestServer) error {
	// Initialen Snapshot senden
	seq := int64(0)
	if err := h.sendSnapshot(stream, seq); err != nil {
		return err
	}

	changeCh, unsub := h.subscribeChanges()
	defer unsub()

	for {
		select {
		case <-stream.Context().Done():
			return nil
		case <-changeCh:
			seq++
			// Alle gepufferten Signale leeren — ein Snapshot deckt alle ab
			for len(changeCh) > 0 {
				<-changeCh
			}
			if err := h.sendSnapshot(stream, seq); err != nil {
				return err
			}
		}
	}
}

func (h *GRPCHandler) sendSnapshot(stream pb.MediaService_WatchManifestServer, seq int64) error {
	files, err := h.store.List()
	if err != nil {
		return status.Errorf(codes.Internal, "list fehlgeschlagen: %v", err)
	}
	assets := make([]*pb.AssetInfo, 0, len(files))
	for _, f := range files {
		assets = append(assets, fileInfoToProto(f))
	}
	return stream.Send(&pb.ManifestEvent{
		Type:   pb.ManifestEvent_MANIFEST_SNAPSHOT,
		Seq:    seq,
		Assets: assets,
	})
}

// ── Proto-Konvertierung ───────────────────────────────────────────────────────

func fileInfoToProto(f FileInfo) *pb.AssetInfo {
	return &pb.AssetInfo{
		AssetId:    f.SHA256,
		Name:       f.Name,
		SizeBytes:  f.SizeBytes,
		MimeType:   f.MimeType,
		ModifiedMs: f.ModifiedMs,
		Audio:      audioInfoToProto(f.Audio),
	}
}

func audioInfoToProto(a *AudioInfo) *pb.AudioMeta {
	if a == nil {
		return nil
	}
	m := &pb.AudioMeta{
		DurationMs: a.DurationMs,
		Channels:   a.Channels,
		SampleRate: a.SampleRate,
		BitDepth:   a.BitDepth,
	}
	if a.LoudnessLufs != nil {
		m.LoudnessLufs = *a.LoudnessLufs
		m.HasLoudness = true
	}
	return m
}

// nameForID gibt den Dateinamen eines gecachten Eintrags zurück.
func (c *Cache) nameForID(assetID string) string {
	c.mu.RLock()
	defer c.mu.RUnlock()
	if e, ok := c.byID[assetID]; ok {
		return e.name
	}
	return ""
}
