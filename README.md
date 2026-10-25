# DualRun

Split-screen iPhone endless runner. Two runners share one input, and the rule for that input changes between phases.

## Run

```sh
open DualRun/DualRun.xcodeproj
```

Select an iPhone simulator and press Run. Portrait only. Deployment target is iOS 16.

## How to play

The screen is split into a top runner and a bottom runner. The center bar is the control.

- **JUMP** clears low blocks.
- **SLIDE** ducks under overhead bars.
- **SYNC** — both runners do exactly what you press. Obstacles match.
- **MIRROR** — the bottom runner does the opposite. Its obstacles are inverted to match.

Either runner crashing ends the run. Tap anywhere to start again. The center bar shows the current phase and how long until it flips.

## Project

`DualRun/DualRun.xcodeproj` is the Xcode project. Game code is under `DualRun/DualRun/`.
