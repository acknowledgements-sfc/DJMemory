# VirtualDJ Plugin Scaffold

Artifact A is a separate C++ Mac `.bundle` built in Xcode. It derives from
`IVdjPluginStartStop8`, polls four decks through the SDK query interface, and
appends the frozen `v:1` JSONL events to
`~/Documents/VirtualDJ/DJMemoryDrop/`.

## Build in Xcode

1. Open `DJMemoryVirtualDJPlugin.xcodeproj`.
2. Select the `DJMemoryVirtualDJPlugin` scheme and **My Mac**.
3. Build with Product → Build.
4. Find the product with Product → Show Build Folder in Finder.

The target currently references the SDK at:

`/Users/robcmartin/Downloads/VirtualDJ8_SDK_20211003`

The Debug product is an ad-hoc signed universal `.bundle` for local testing.
Developer ID signing and notarization are intentionally separate from
`DJMemory.app`.

For live development, VirtualDJ documents architecture-specific plugin folders:

- Apple Silicon: `~/Documents/VirtualDJ/PluginsArm/Other/`
- Intel: `~/Documents/VirtualDJ/Plugins64/Other/`

The sandboxed VirtualDJ 2026 installation tested on 2026-08-13 stores its live
Apple Silicon plugin tree at:

`~/Library/Containers/com.atomixproductions.virtualdj/Data/Library/Application Support/VirtualDJ/PluginsMacArm/`

Its `AutoStart` subfolder is the observed location for general startup plugins.
General/basic plugins may require a VirtualDJ Pro-capable license; the tested
session did not load the bundle under its current license tier. Restart
VirtualDJ after replacing the bundle.

## Live validation still required

The SDK C++ surface, bundle export, universal binary, and local ad-hoc signature
compile against the supplied headers.
The VDJScript getter strings in `VDJSDKAdapter.cpp` still need a real
VirtualDJ test, including whether SDK queries may run on the polling worker
thread and whether `deck N play` is a strong enough on-air signal. Keep M14 at
Research until a played set writes JSONL and DJMemory imports and matches it.

See [../m14-vdj-plugin-spec.md](../m14-vdj-plugin-spec.md) for the event contract
and validation checklist. No private APIs, network access, or audio capture are
used by this target.
