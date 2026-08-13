# VirtualDJ Plugin Scaffold
Placeholder for a future Mac `.bundle` (Artifact A). See
[../m14-vdj-plugin-spec.md](../m14-vdj-plugin-spec.md) for the full M14 spec:
SDK surface, event model, the frozen `v:1` JSONL schema this plugin must emit,
and the `~/Documents/VirtualDJ/DJMemoryDrop/` drop-folder contract.

Artifact B (Swift `.jsonl` ingest) is implemented: `JSONLTracklistParser` in
`Sources/DJMemoryCore/VirtualDJPluginEvent.swift`, routed from
`VirtualDJHistoryParser` for `.jsonl` files. Do not start this C++ plugin until
the VirtualDJ SDK headers are verified (spec §3). No private APIs.
