# ToddlerKeys

A tiny macOS toy: mash the keyboard, get notes and silly sounds.

No sample packs, no permissions. Letters play a pentatonic scale so random
mashing still sounds friendly. Numbers and a few special keys play synthesized
effects (boing, duck, laser, siren…).

## Run

Open `ToddlerKeys.xcodeproj` in Xcode, pick the **ToddlerKeys** scheme, press Run.

Or from the repo root:

```sh
xcodebuild -scheme ToddlerKeys -destination 'platform=macOS' build
```

The built app lands under Xcode’s DerivedData. From Xcode, Run is the easy path.

## How it plays

| Keys | Sound |
| --- | --- |
| `A`–`Z` | Musical notes (C pentatonic, low keys on the bottom row) |
| `1`–`0` | Silly effects |
| Space | Kick |
| Return | Fanfare |
| Tab | Chord |
| Delete | Rewind |
| Arrow keys | Slides |
| On-screen keys | Same sounds, clickable |

The app only listens while it is frontmost, so it does not need Accessibility
access. Parent shortcuts (`⌘Q`, `⌘W`, `⌘H`, `⌘M`) still work.

## MVP scope

- Native SwiftUI Mac app
- Polyphonic synthesized audio (no audio files)
- Big visual bursts + a light-up keyboard
- Key-repeat ignored so a stuck key does not scream

## Later, maybe

Custom sound packs, a true baby-lock, and a fullscreen kiosk mode.
