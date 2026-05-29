package node

import (
	"context"
	"errors"
	"sync"

	"github.com/google/uuid"
	pb "stagesync-server/gen/go/stagesync/v1"
)

var ErrNodeNotConnected = errors.New("node not connected to command stream")

// nodeEntry hält Channel + Tasks eines verbundenen Nodes.
type nodeEntry struct {
	ch    chan *pb.NodeCommandRequest
	tasks []pb.NodeTask
}

// Dispatcher verteilt NodeCommands an verbundene Nodes.
// Unterstützt direktes Routing (nodeID) und task-basiertes Routing.
type Dispatcher struct {
	mu    sync.RWMutex
	nodes map[string]*nodeEntry // nodeID → entry
}

func NewDispatcher() *Dispatcher {
	return &Dispatcher{nodes: make(map[string]*nodeEntry)}
}

// Register erstellt einen Command-Channel für einen Node.
func (d *Dispatcher) Register(nodeID string, tasks []pb.NodeTask) chan *pb.NodeCommandRequest {
	ch := make(chan *pb.NodeCommandRequest, 32)
	d.mu.Lock()
	d.nodes[nodeID] = &nodeEntry{ch: ch, tasks: tasks}
	d.mu.Unlock()
	return ch
}

// UpdateTasks aktualisiert die Task-Liste eines bereits verbundenen Nodes.
func (d *Dispatcher) UpdateTasks(nodeID string, tasks []pb.NodeTask) {
	d.mu.Lock()
	if e, ok := d.nodes[nodeID]; ok {
		e.tasks = tasks
	}
	d.mu.Unlock()
}

// Unregister entfernt den Channel.
func (d *Dispatcher) Unregister(nodeID string) {
	d.mu.Lock()
	if e, ok := d.nodes[nodeID]; ok {
		close(e.ch)
		delete(d.nodes, nodeID)
	}
	d.mu.Unlock()
}

// Dispatch sendet an einen spezifischen Node per ID.
func (d *Dispatcher) Dispatch(ctx context.Context, nodeID string, cmd *pb.NodeCommandRequest) error {
	d.mu.RLock()
	e, ok := d.nodes[nodeID]
	d.mu.RUnlock()
	if !ok {
		return ErrNodeNotConnected
	}
	return d.send(ctx, e.ch, cmd)
}

// DispatchToTask sendet an alle verbundenen Nodes, die den gegebenen Task haben.
// Gibt den ersten Fehler zurück; sendet aber an alle zutreffenden Nodes.
func (d *Dispatcher) DispatchToTask(ctx context.Context, task pb.NodeTask, cmd *pb.NodeCommandRequest) error {
	d.mu.RLock()
	var targets []chan *pb.NodeCommandRequest
	for _, e := range d.nodes {
		for _, t := range e.tasks {
			if t == task {
				targets = append(targets, e.ch)
				break
			}
		}
	}
	d.mu.RUnlock()

	if len(targets) == 0 {
		return ErrNodeNotConnected
	}

	var firstErr error
	for _, ch := range targets {
		if err := d.send(ctx, ch, cmd); err != nil && firstErr == nil {
			firstErr = err
		}
	}
	return firstErr
}

func (d *Dispatcher) send(ctx context.Context, ch chan *pb.NodeCommandRequest, cmd *pb.NodeCommandRequest) error {
	if cmd.CommandId == "" {
		cmd.CommandId = uuid.NewString()
	}
	select {
	case ch <- cmd:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// ConnectedNodeIDs gibt alle Nodes zurück, die einen Command-Stream offen haben.
func (d *Dispatcher) ConnectedNodeIDs() []string {
	d.mu.RLock()
	defer d.mu.RUnlock()
	ids := make([]string, 0, len(d.nodes))
	for id := range d.nodes {
		ids = append(ids, id)
	}
	return ids
}
