# VirtualDJ Native Plugin Path (M14)

DJMemory treats a VirtualDJ Mac `.bundle` as a separate artifact. It should emit JSONL set/track events into a local drop folder for import as ImportedTracklist. Status: Research until verified. No private APIs.

Full design (SDK surface, event model, JSONL schema, drop-folder location, sandbox notes, build order): see [m14-vdj-plugin-spec.md](m14-vdj-plugin-spec.md).
