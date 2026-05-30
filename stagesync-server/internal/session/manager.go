package session

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/google/uuid"
	pb "stagesync-server/gen/go/stagesync/v1"
)

var (
	ErrSessionNotFound    = errors.New("session not found")
	ErrSessionExists      = errors.New("session already exists")
	ErrInvalidToken       = errors.New("invalid or expired token")
	ErrInvalidPassword    = errors.New("wrong session password")
	ErrNodeNotFound       = errors.New("node not found")
	ErrPermissionDenied   = errors.New("permission denied: insufficient role")
)

// Manager verwaltet alle aktiven Sessions auf diesem Server.
type Manager struct {
	mu       sync.RWMutex
	sessions map[string]*Session // sessionID → Session

	heartbeatTimeout time.Duration
	persist          *Persistence
}

func NewManager(dataDir string) *Manager {
	m := &Manager{
		sessions:         make(map[string]*Session),
		heartbeatTimeout: 15 * time.Second,
		persist:          NewPersistence(dataDir),
	}
	// Persistente Sessions wiederherstellen (überleben Server-Neustart).
	for _, s := range m.persist.Load() {
		m.sessions[s.ID] = s
		log.Printf("[session] persistente Session wiederhergestellt: %q (%s)", s.Name, s.ID)
	}
	go m.watchdogLoop()
	return m
}

// savePersistent schreibt alle persistenten Sessions auf Disk.
func (m *Manager) savePersistent() {
	m.persist.Save(m.AllSessions())
}

// CreateSession erstellt eine neue Session. Der anfragende Node wird Master.
func (m *Manager) CreateSession(req *pb.CreateSessionRequest) (*Session, string, error) {
	if req.MyNode == nil {
		return nil, "", errors.New("node info required")
	}

	sessionID := uuid.NewString()
	nodeID := ensureNodeID(req.MyNode)
	token := generateToken()

	passHash := ""
	if req.Password != "" {
		passHash = simpleHash(req.Password)
	}

	sess := NewSession(sessionID, req.SessionName, req.ShowName, passHash, nodeID)
	sess.Persistent = req.Persistent

	req.MyNode.NodeId = nodeID
	req.MyNode.NodeRole = pb.NodeRole_NODE_ROLE_MASTER
	req.MyNode.Online = true

	sess.AddNode(&Node{
		Info:     req.MyNode,
		Token:    token,
		LastSeen: time.Now(),
		Online:   true,
	})

	m.mu.Lock()
	m.sessions[sessionID] = sess
	m.mu.Unlock()

	if sess.Persistent {
		m.savePersistent()
	}

	return sess, token, nil
}

// JoinSession lässt einen Node einer bestehenden Session beitreten.
func (m *Manager) JoinSession(req *pb.JoinSessionRequest) (*Session, string, error) {
	if req.MyNode == nil {
		return nil, "", errors.New("node info required")
	}

	m.mu.RLock()
	sess, ok := m.sessions[req.SessionId]
	m.mu.RUnlock()
	if !ok {
		return nil, "", ErrSessionNotFound
	}

	if sess.PassHash != "" && simpleHash(req.Password) != sess.PassHash {
		return nil, "", ErrInvalidPassword
	}

	nodeID := ensureNodeID(req.MyNode)
	token := generateToken()

	req.MyNode.NodeId = nodeID
	req.MyNode.Online = true

	// Erster beitretender Node ohne explizite Role wird Client
	if req.MyNode.NodeRole == pb.NodeRole_NODE_ROLE_UNSPECIFIED {
		req.MyNode.NodeRole = pb.NodeRole_NODE_ROLE_CLIENT
	}

	sess.AddNode(&Node{
		Info:     req.MyNode,
		Token:    token,
		LastSeen: time.Now(),
		Online:   true,
	})

	// Kein Online-Master (z.B. nach Neustart einer persistenten Session)?
	// → der beitretende Node übernimmt die Master-Rolle.
	masterChanged := false
	if !sess.hasOnlineMaster() {
		sess.mu.Lock()
		sess.MasterID = req.MyNode.NodeId
		sess.mu.Unlock()
		req.MyNode.NodeRole = pb.NodeRole_NODE_ROLE_MASTER
		masterChanged = true
	}

	sess.BroadcastEvent(&pb.SessionEvent{
		Type:         pb.SessionEvent_TYPE_NODE_JOINED,
		Session:      sess.ToProto(),
		AffectedNode: req.MyNode,
		OccurredAt:   nowProto(),
	})
	if masterChanged {
		sess.BroadcastEvent(&pb.SessionEvent{
			Type:         pb.SessionEvent_TYPE_MASTER_CHANGED,
			Session:      sess.ToProto(),
			AffectedNode: req.MyNode,
			OccurredAt:   nowProto(),
		})
		if sess.Persistent {
			m.savePersistent()
		}
	}

	return sess, token, nil
}

// LeaveSession entfernt einen Node aus der Session.
func (m *Manager) LeaveSession(sessionID, nodeID, token string) error {
	sess, err := m.getAndValidate(sessionID, token)
	if err != nil {
		return err
	}

	node, ok := sess.GetNode(nodeID)
	if !ok {
		return ErrNodeNotFound
	}

	sess.RemoveNode(nodeID)

	sess.BroadcastEvent(&pb.SessionEvent{
		Type:         pb.SessionEvent_TYPE_NODE_LEFT,
		Session:      sess.ToProto(),
		AffectedNode: node.Info,
		OccurredAt:   nowProto(),
	})

	// Wenn Master weg, Leader Election anstoßen
	if sess.MasterID == nodeID {
		m.electNewMaster(sess)
	}

	return nil
}

// Heartbeat aktualisiert den LastSeen-Zeitstempel eines Nodes.
func (m *Manager) Heartbeat(sessionID, nodeID, token string) error {
	sess, err := m.getAndValidate(sessionID, token)
	if err != nil {
		return err
	}

	node, ok := sess.GetNode(nodeID)
	if !ok {
		return ErrNodeNotFound
	}
	node.LastSeen = time.Now()
	node.Online = true
	return nil
}

// ValidateToken prüft Token und gibt Session + NodeID zurück.
func (m *Manager) ValidateToken(sessionID, token string) (*Session, string, error) {
	m.mu.RLock()
	sess, ok := m.sessions[sessionID]
	m.mu.RUnlock()
	if !ok {
		return nil, "", ErrSessionNotFound
	}

	nodeID, valid := sess.ValidateToken(token)
	if !valid {
		return nil, "", ErrInvalidToken
	}
	return sess, nodeID, nil
}

// GetSession gibt eine Session zurück (ohne Token-Prüfung, für interne Nutzung).
func (m *Manager) GetSession(sessionID string) (*Session, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	sess, ok := m.sessions[sessionID]
	if !ok {
		return nil, ErrSessionNotFound
	}
	return sess, nil
}

// AllSessions gibt alle aktiven Sessions zurück.
func (m *Manager) AllSessions() []*Session {
	m.mu.RLock()
	defer m.mu.RUnlock()
	out := make([]*Session, 0, len(m.sessions))
	for _, s := range m.sessions {
		out = append(out, s)
	}
	return out
}

// getAndValidate ist ein interner Helfer für Token-Validierung.
func (m *Manager) getAndValidate(sessionID, token string) (*Session, error) {
	sess, _, err := m.ValidateToken(sessionID, token)
	return sess, err
}

// electNewMaster wählt den nächsten Online-Node (Backup-Role bevorzugt) zum Master.
func (m *Manager) electNewMaster(sess *Session) {
	var backup, anyOnline *Node
	for _, n := range sess.AllNodes() {
		if !n.Online {
			continue
		}
		if n.Info.NodeRole == pb.NodeRole_NODE_ROLE_BACKUP {
			backup = n
			break
		}
		if anyOnline == nil {
			anyOnline = n
		}
	}

	candidate := backup
	if candidate == nil {
		candidate = anyOnline
	}
	if candidate == nil {
		return
	}

	sess.mu.Lock()
	sess.MasterID = candidate.Info.NodeId
	candidate.Info.NodeRole = pb.NodeRole_NODE_ROLE_MASTER
	sess.mu.Unlock()

	sess.BroadcastEvent(&pb.SessionEvent{
		Type:         pb.SessionEvent_TYPE_MASTER_CHANGED,
		Session:      sess.ToProto(),
		AffectedNode: candidate.Info,
		OccurredAt:   nowProto(),
	})

	if sess.Persistent {
		m.savePersistent()
	}
}

// watchdogLoop prüft regelmäßig Heartbeats und markiert Nodes als Offline.
func (m *Manager) watchdogLoop() {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()
	for range ticker.C {
		m.mu.RLock()
		sessions := make([]*Session, 0, len(m.sessions))
		for _, s := range m.sessions {
			sessions = append(sessions, s)
		}
		m.mu.RUnlock()

		for _, sess := range sessions {
			for _, node := range sess.AllNodes() {
				if node.Online && time.Since(node.LastSeen) > m.heartbeatTimeout {
					if sess.MarkOffline(node.Info.NodeId) {
						sess.BroadcastEvent(&pb.SessionEvent{
							Type:         pb.SessionEvent_TYPE_NODE_OFFLINE,
							Session:      sess.ToProto(),
							AffectedNode: node.Info,
							OccurredAt:   nowProto(),
						})
						if sess.MasterID == node.Info.NodeId {
							m.electNewMaster(sess)
						}
					}
				}
			}
		}
	}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func ensureNodeID(node *pb.NodeInfo) string {
	if node.NodeId != "" {
		return node.NodeId
	}
	return uuid.NewString()
}

func generateToken() string {
	b := make([]byte, 24)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

// simpleHash: In Produktion durch bcrypt ersetzen.
// Für Phase 1 reicht ein deterministischer Hash.
func simpleHash(s string) string {
	return fmt.Sprintf("h:%x", []byte(s))
}

func nowProto() *pb.Timestamp {
	return &pb.Timestamp{UnixMillis: time.Now().UnixMilli()}
}

// AddInternalNode fügt einen server-internen Node direkt in eine Session ein,
// ohne gRPC-Roundtrip. Wird für den optionalen --audio-node Modus genutzt.
// Gibt nodeID und Token zurück.
func (m *Manager) AddInternalNode(sessionID string, info *pb.NodeInfo) (nodeID, token string, err error) {
	sess, err := m.GetSession(sessionID)
	if err != nil {
		return "", "", err
	}
	nodeID = ensureNodeID(info)
	info.NodeId = nodeID
	info.Online = true
	tok := generateToken()
	node := &Node{
		Info:     info,
		Token:    tok,
		LastSeen: time.Now(),
		Online:   true,
	}
	sess.AddNode(node)
	sess.BroadcastEvent(&pb.SessionEvent{
		Type:         pb.SessionEvent_TYPE_NODE_JOINED,
		Session:      sess.ToProto(),
		AffectedNode: info,
		OccurredAt:   nowProto(),
	})
	log.Printf("[session] internal node added: %s (%s) in session %s", info.Name, info.NodeType, sessionID)
	return nodeID, tok, nil
}

// NotifyNodeUpdated broadcastet ein Update-Event für einen Node (z.B. nach
// RegisterNode, wenn sich Capabilities wie die MediaServerUrl ändern).
func (m *Manager) NotifyNodeUpdated(sessionID string, nodeInfo *pb.NodeInfo) {
	sess, err := m.GetSession(sessionID)
	if err != nil {
		return
	}
	sess.BroadcastEvent(&pb.SessionEvent{
		Type:         pb.SessionEvent_TYPE_NODE_JOINED,
		Session:      sess.ToProto(),
		AffectedNode: nodeInfo,
		OccurredAt:   nowProto(),
	})
}

// WatchSession gibt den Event-Channel und die Session zurück.
// Der Handler kann danach den aktuellen Stand als erstes Event senden.
func (m *Manager) WatchSession(ctx context.Context, sessionID string) (<-chan *pb.SessionEvent, *Session, error) {
	sess, err := m.GetSession(sessionID)
	if err != nil {
		return nil, nil, err
	}

	ch := sess.Subscribe()

	go func() {
		<-ctx.Done()
		sess.Unsubscribe(ch)
	}()

	return ch, sess, nil
}
