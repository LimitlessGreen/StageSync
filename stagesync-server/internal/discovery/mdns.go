package discovery

import (
	"context"
	"fmt"
	"log"

	"github.com/grandcat/zeroconf"
)

const (
	ServiceType = "_stagesync._tcp"
	Domain      = "local."
)

// Server kündigt den StageSync-Server per mDNS an.
// Nodes im LAN können ihn so ohne manuelle IP-Konfiguration finden.
type Server struct {
	server *zeroconf.Server
}

func Announce(ctx context.Context, name string, port int, txtRecords []string) (*Server, error) {
	srv, err := zeroconf.Register(
		name,
		ServiceType,
		Domain,
		port,
		txtRecords,
		nil, // alle Interfaces
	)
	if err != nil {
		return nil, fmt.Errorf("mDNS announce: %w", err)
	}

	go func() {
		<-ctx.Done()
		srv.Shutdown()
		log.Println("mDNS: service deregistered")
	}()

	log.Printf("mDNS: announcing %q on port %d", name, port)
	return &Server{server: srv}, nil
}

// BrowseResult enthält einen gefundenen StageSync-Server.
type BrowseResult struct {
	Name    string
	Host    string
	Port    int
	TxtMap  map[string]string
}

// Browse sucht nach StageSync-Servern im LAN.
// Ergebnisse werden über den zurückgegebenen Channel gesendet.
func Browse(ctx context.Context) (<-chan BrowseResult, error) {
	resolver, err := zeroconf.NewResolver(nil)
	if err != nil {
		return nil, fmt.Errorf("mDNS resolver: %w", err)
	}

	entries := make(chan *zeroconf.ServiceEntry, 16)
	results := make(chan BrowseResult, 16)

	go func() {
		defer close(results)
		for entry := range entries {
			host := entry.HostName
			if len(entry.AddrIPv4) > 0 {
				host = entry.AddrIPv4[0].String()
			}

			txt := parseTxt(entry.Text)
			results <- BrowseResult{
				Name:   entry.ServiceInstanceName(),
				Host:   host,
				Port:   entry.Port,
				TxtMap: txt,
			}
		}
	}()

	go func() {
		if err := resolver.Browse(ctx, ServiceType, Domain, entries); err != nil {
			log.Printf("mDNS browse error: %v", err)
		}
		close(entries)
	}()

	return results, nil
}

func parseTxt(records []string) map[string]string {
	m := make(map[string]string, len(records))
	for _, r := range records {
		for i, ch := range r {
			if ch == '=' {
				m[r[:i]] = r[i+1:]
				break
			}
		}
	}
	return m
}
