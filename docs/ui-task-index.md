# UI task index

Tracking goal: [#1](https://github.com/acknowledgements-sfc/DJMemory/issues/1)
Spec: [`HANDOFF.md`](../HANDOFF.md) · Rules: [`AGENTS.md`](../AGENTS.md)

Work these strictly in order. T1–T4 are structural; every screen task depends on them.

| | Task | Issue |
| --- | --- | --- |
| T1 | Design token layer (`Theme/Tokens.swift`) | [#2](https://github.com/acknowledgements-sfc/DJMemory/issues/2) |
| T2 | Split `ContentView.swift`, add `Route` enum | [#3](https://github.com/acknowledgements-sfc/DJMemory/issues/3) |
| T3 | Shared UI primitives | [#4](https://github.com/acknowledgements-sfc/DJMemory/issues/4) |
| T4 | `DJMemoryCore` gaps G1–G5 | [#5](https://github.com/acknowledgements-sfc/DJMemory/issues/5) |
| T5 | Protection dashboard | [#6](https://github.com/acknowledgements-sfc/DJMemory/issues/6) |
| T6 | Per-app setup | [#7](https://github.com/acknowledgements-sfc/DJMemory/issues/7) |
| T7 | Library | [#8](https://github.com/acknowledgements-sfc/DJMemory/issues/8) |
| T8 | Activity + Settings | [#9](https://github.com/acknowledgements-sfc/DJMemory/issues/9) |
| T9 | Onboarding flow | [#10](https://github.com/acknowledgements-sfc/DJMemory/issues/10) |
| T10 | Folder recovery flow | [#11](https://github.com/acknowledgements-sfc/DJMemory/issues/11) |
| T11 | Previews and interaction polish | [#12](https://github.com/acknowledgements-sfc/DJMemory/issues/12) |

One PR per task. `swift build`, `swift test`, and `bash scripts/smoke-app.sh` must pass, and every
existing `.accessibilityIdentifier` must survive.
