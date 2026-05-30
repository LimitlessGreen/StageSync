// Re-exports the authoritative SessionScreen from the legacy location.
//
// The legacy screen is feature-complete (mDNS discovery, create/join,
// task selection, audio/MA setup). This file provides the canonical
// import path under lib/showcontrol/ui/screens/ per the architecture plan.
// A full rewrite using the new design system is planned for Phase 6.
export 'package:theatre_companion_app/ui/screens/showcontrol/session_screen.dart'
    show SessionScreen;
