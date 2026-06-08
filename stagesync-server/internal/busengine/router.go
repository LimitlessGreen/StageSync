// Package busengine resolves audio bus routing:
// BusSends (from cues or talkback) → NodeTargets (nodeID + deviceIndex + level).
//
// It also handles migration from the legacy PatchConfig logical-output model:
// any PatchConfig that has buses[] populated uses the bus model;
// one without buses[] is automatically converted to a set of MAIN buses.
package busengine

import (
	"log"
	"sync"

	pb "stagesync-server/gen/go/stagesync/v1"
)

// NodeTarget is a resolved playback destination.
type NodeTarget struct {
	NodeID      string
	DeviceIndex int32
	LevelDB     float32 // combined bus output + send level
}

// Router resolves BusSends to NodeTargets using the current PatchConfig.
// It is safe for concurrent use.
type Router struct {
	mu     sync.RWMutex
	buses  map[string]*pb.AudioBus  // bus_id → bus
	byType map[pb.AudioBusType][]*pb.AudioBus
}

// NewRouter creates an empty Router.
func NewRouter() *Router {
	return &Router{
		buses:  make(map[string]*pb.AudioBus),
		byType: make(map[pb.AudioBusType][]*pb.AudioBus),
	}
}

// Update replaces the router state from a PatchConfig.
// If patch.Buses is empty, the legacy logical_outputs are migrated to MAIN buses.
func (r *Router) Update(patch *pb.PatchConfig) {
	if patch == nil {
		return
	}

	buses := patch.Buses
	if len(buses) == 0 && len(patch.LogicalOutputs) > 0 {
		buses = migrateLegacy(patch)
		log.Printf("[busengine] migriert %d LogicalOutputs zu Buses", len(buses))
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	r.buses = make(map[string]*pb.AudioBus, len(buses))
	r.byType = make(map[pb.AudioBusType][]*pb.AudioBus)

	for _, b := range buses {
		r.buses[b.Id] = b
		r.byType[b.Type] = append(r.byType[b.Type], b)
	}
}

// Resolve converts a list of BusSends to concrete NodeTargets.
// Sends with enabled=false or pointing to a muted bus are skipped.
// If sends is empty, all buses of type MAIN are used with 0 dB send level.
func (r *Router) Resolve(sends []*pb.BusSend) []NodeTarget {
	r.mu.RLock()
	defer r.mu.RUnlock()

	// Default: sends leer → alle MAIN-Buses mit 0 dB
	if len(sends) == 0 {
		sends = r.defaultMainSends()
	}

	seen := make(map[string]float32) // nodeID+device → max level (dedup)
	var targets []NodeTarget

	for _, send := range sends {
		bus, ok := r.buses[send.BusId]
		if !ok || bus.Muted {
			continue
		}

		combinedDB := send.SendLevelDb + bus.OutputLevelDb

		for _, assign := range bus.Patch {
			key := assign.NodeId + "|" + string(rune(assign.DeviceIndex))
			if existing, dup := seen[key]; dup {
				// Keep highest level for the same destination
				if combinedDB > existing {
					seen[key] = combinedDB
					// Update in targets slice
					for i := range targets {
						if targets[i].NodeID == assign.NodeId && targets[i].DeviceIndex == assign.DeviceIndex {
							targets[i].LevelDB = combinedDB
						}
					}
				}
				continue
			}
			seen[key] = combinedDB
			targets = append(targets, NodeTarget{
				NodeID:      assign.NodeId,
				DeviceIndex: assign.DeviceIndex,
				LevelDB:     combinedDB,
			})
		}
	}
	return targets
}

// ResolveTalkbackBuses returns NodeTargets for all TALKBACK buses.
// If targetBusIDs is non-empty, only those buses are used.
func (r *Router) ResolveTalkbackBuses(targetBusIDs []string) []NodeTarget {
	r.mu.RLock()
	defer r.mu.RUnlock()

	// Buses bestimmen (unter Lock)
	var busIDs []string
	if len(targetBusIDs) > 0 {
		busIDs = targetBusIDs
	} else {
		for _, b := range r.byType[pb.AudioBusType_AUDIO_BUS_TYPE_TALKBACK] {
			busIDs = append(busIDs, b.Id)
		}
	}

	// NodeTargets direkt auflösen (kein separates Resolve() — vermeidet Mutex-Verschachtelung)
	seen := make(map[string]struct{})
	var targets []NodeTarget
	for _, id := range busIDs {
		bus, ok := r.buses[id]
		if !ok || bus.Muted {
			continue
		}
		for _, assign := range bus.Patch {
			key := assign.NodeId + "|" + string(rune(assign.DeviceIndex))
			if _, dup := seen[key]; dup {
				continue
			}
			seen[key] = struct{}{}
			targets = append(targets, NodeTarget{
				NodeID:      assign.NodeId,
				DeviceIndex: assign.DeviceIndex,
				LevelDB:     bus.OutputLevelDb,
			})
		}
	}
	return targets
}

// Buses returns a snapshot of all current buses (for UI).
func (r *Router) Buses() []*pb.AudioBus {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]*pb.AudioBus, 0, len(r.buses))
	for _, b := range r.buses {
		out = append(out, b)
	}
	return out
}

// ── helpers ───────────────────────────────────────────────────────────────────

func (r *Router) defaultMainSends() []*pb.BusSend {
	mains := r.byType[pb.AudioBusType_AUDIO_BUS_TYPE_MAIN]
	sends := make([]*pb.BusSend, len(mains))
	for i, b := range mains {
		sends[i] = &pb.BusSend{BusId: b.Id, SendLevelDb: 0, Enabled: true}
	}
	return sends
}

// migrateLegacy converts the legacy 3-layer PatchConfig to AudioBus messages.
// Each LogicalOutput becomes a MAIN bus whose patch is built from node_assigns
// and device_assigns.
func migrateLegacy(patch *pb.PatchConfig) []*pb.AudioBus {
	// Build quick-lookup maps
	nodeIDs := make(map[string][]string) // logical_output_id → node_ids
	for _, na := range patch.NodeAssigns {
		nodeIDs[na.LogicalOutputId] = na.NodeIds
	}
	deviceIdx := make(map[string]map[string]int32) // logical_output_id → node_id → device_index
	for _, da := range patch.DeviceAssigns {
		if deviceIdx[da.LogicalOutputId] == nil {
			deviceIdx[da.LogicalOutputId] = make(map[string]int32)
		}
		deviceIdx[da.LogicalOutputId][da.NodeId] = da.DeviceIndex
	}

	buses := make([]*pb.AudioBus, 0, len(patch.LogicalOutputs))
	for _, lo := range patch.LogicalOutputs {
		bus := &pb.AudioBus{
			Id:            lo.Id,
			Name:          lo.Name,
			Type:          pb.AudioBusType_AUDIO_BUS_TYPE_MAIN,
			OutputLevelDb: 0,
		}
		for _, nid := range nodeIDs[lo.Id] {
			assign := &pb.BusNodeAssign{NodeId: nid}
			if devMap, ok := deviceIdx[lo.Id]; ok {
				assign.DeviceIndex = devMap[nid]
			}
			bus.Patch = append(bus.Patch, assign)
		}
		buses = append(buses, bus)
	}
	return buses
}
