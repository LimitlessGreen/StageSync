package session

import (
	"log"
	"sync"
	"time"

	pb "stagesync-server/gen/go/stagesync/v1"
	"google.golang.org/protobuf/proto"
)

type Session struct {
	mu sync.RWMutex

	ID         string
	Name       string
	ShowName   string
	PassHash   string // bcrypt-Hash, leer = kein Passwort
	MasterID   string
	CreatedAt  time.Time
	Persistent bool // überlebt Server-Neustart (auf Disk gesichert)

	nodes       map[string]*Node
	tokens      map[string]string // token → nodeID
	subMu       sync.Mutex
	subscribers []chan *pb.SessionEvent // Fan-out: jeder Subscriber bekommt alle Events
}

type Node struct {
	Info         *pb.NodeInfo
	Capabilities *pb.NodeCapabilities
	Token        string
	LastSeen     time.Time
	Online       bool
}

func NewSession(id, name, showName, passHash, masterNodeID string) *Session {
	return &Session{
		ID:        id,
		Name:      name,
		ShowName:  showName,
		PassHash:  passHash,
		MasterID:  masterNodeID,
		CreatedAt: time.Now(),
		nodes:     make(map[string]*Node),
		tokens:    make(map[string]string),
	}
}

func (s *Session) AddNode(node *Node) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.nodes[node.Info.NodeId] = node
	s.tokens[node.Token] = node.Info.NodeId
}

func (s *Session) RemoveNode(nodeID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if n, ok := s.nodes[nodeID]; ok {
		delete(s.tokens, n.Token)
		delete(s.nodes, nodeID)
	}
}

func (s *Session) ValidateToken(token string) (nodeID string, ok bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	nodeID, ok = s.tokens[token]
	return
}

func (s *Session) GetNode(nodeID string) (*Node, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	n, ok := s.nodes[nodeID]
	return n, ok
}

func (s *Session) AllNodes() []*Node {
	s.mu.RLock()
	defer s.mu.RUnlock()
	nodes := make([]*Node, 0, len(s.nodes))
	for _, n := range s.nodes {
		nodes = append(nodes, n)
	}
	return nodes
}

// hasOnlineMaster prüft, ob der aktuelle Master existiert und online ist.
func (s *Session) hasOnlineMaster() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if s.MasterID == "" {
		return false
	}
	n, ok := s.nodes[s.MasterID]
	return ok && n.Online
}

func (s *Session) MarkOffline(nodeID string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if n, ok := s.nodes[nodeID]; ok {
		n.Online = false
		return true
	}
	return false
}

// Subscribe registriert einen neuen Subscriber und gibt seinen Channel zurück.
func (s *Session) Subscribe() chan *pb.SessionEvent {
	ch := make(chan *pb.SessionEvent, 32)
	s.subMu.Lock()
	s.subscribers = append(s.subscribers, ch)
	s.subMu.Unlock()
	return ch
}

// Unsubscribe entfernt den Subscriber und schließt seinen Channel.
func (s *Session) Unsubscribe(ch chan *pb.SessionEvent) {
	s.subMu.Lock()
	defer s.subMu.Unlock()
	for i, sub := range s.subscribers {
		if sub == ch {
			s.subscribers = append(s.subscribers[:i], s.subscribers[i+1:]...)
			close(ch)
			return
		}
	}
}

// BroadcastEvent sendet ein Event an ALLE Subscriber (echter Fan-out).
func (s *Session) BroadcastEvent(ev *pb.SessionEvent) {
	s.subMu.Lock()
	defer s.subMu.Unlock()
	for _, ch := range s.subscribers {
		select {
		case ch <- ev:
		default: // Subscriber zu langsam — Event verwerfen statt blockieren
		}
	}
}

// SetNodeMediaServerUrl setzt die MediaServerUrl eines Nodes thread-sicher.
func (s *Session) SetNodeMediaServerUrl(nodeID, url string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if n, ok := s.nodes[nodeID]; ok {
		n.Info.MediaServerUrl = url
		log.Printf("[Session] SetNodeMediaServerUrl node=%s url=%q → gesetzt auf %q", nodeID, url, n.Info.MediaServerUrl)
	} else {
		log.Printf("[Session] SetNodeMediaServerUrl FEHLER: node=%s nicht gefunden! nodes=%v", nodeID, func() []string {
			keys := make([]string, 0, len(s.nodes))
			for k := range s.nodes {
				keys = append(keys, k)
			}
			return keys
		}())
	}
}

func (s *Session) ToProto() *pb.Session {
	s.mu.RLock()
	defer s.mu.RUnlock()

	nodes := make([]*pb.NodeInfo, 0, len(s.nodes))
	for _, n := range s.nodes {
		// Clone verhindert Pointer-Sharing: kein Race zwischen ToProto und
		// concurrent Mutations (z.B. SetNodeMediaServerUrl).
		nodes = append(nodes, proto.Clone(n.Info).(*pb.NodeInfo))
	}
	return &pb.Session{
		SessionId:         s.ID,
		Name:              s.Name,
		ShowName:          s.ShowName,
		PasswordProtected: s.PassHash != "",
		MasterNodeId:      s.MasterID,
		Nodes:             nodes,
		CreatedAt:         &pb.Timestamp{UnixMillis: s.CreatedAt.UnixMilli()},
		Persistent:        s.Persistent,
	}
}
