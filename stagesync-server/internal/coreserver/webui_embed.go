package coreserver

import "embed"

// embeddedWebUI holds the Flutter web build output used as a fallback when
// no external -web-ui-dir is configured. It contains only a placeholder
// page unless the build output has been copied into ./webui/.
//
//go:embed webui
var embeddedWebUI embed.FS
