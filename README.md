# Mr.Blobsky

A tiny macOS menu-bar toy: mash the keyboard, get notes and silly sounds.

It sits in the menu bar until you press **⌥⌘K** (or choose **Lock Keyboard**).
That locks the keyboard so other apps do not receive keys, and blob-cat
stickers fly out across the screen. The idle face is a blob kitty. Follow-along
songs are optional. The same hotkey or **Unlock** turns lock off.

Stickers are Blob Cats (Apache 2.0 via DuckOfDisorder/BlobCats, derived from
Google blob art) plus a few Slackmoji blob-cat GIFs. Not Hello Kitty or other
trademarked characters. See `THIRD_PARTY_BLOBCATS_LICENSE`. [Privacy](PRIVACY.md).

Letters and F-keys play a pentatonic scale so random mashing still sounds
friendly. Pretty much every other key has its own synthesized effect.

## Run

Open `MrBlobsky.xcodeproj` in Xcode, pick the **MrBlobsky** scheme, press Run.

Or from the repo root:

```sh
xcodebuild -scheme MrBlobsky -destination 'platform=macOS' build
```

The built app lands under Xcode’s DerivedData. From Xcode, Run is the easy path.

## How it plays

| Keys | Sound |
| --- | --- |
| `A`–`Z`, F1–F12 | Musical notes (C pentatonic) |
| `1`–`0` | Silly effects (boing, quack, laser…) |
| Punctuation | More effects (robot, drip, ding, meow…) |
| Space / Return / Tab / Delete | Kick, fanfare, chord, rewind |
| Shift / Caps / Ctrl / Opt / ⌘ / fn | Clack, giggle, spark, magic, wow, click |
| Arrow keys | Slides |
| Keypad, Home, End, Page Up/Down | Same family of notes and effects |
| On-screen keys | Full laptop layout, clickable |
| Trackpad click/tap | A rotating surprise sound and sticker burst |

Any leftover key still makes a sound from its key code, so a full-size keyboard is covered too.

## Menu bar & lock

| Action | How |
| --- | --- |
| Lock + overlay | `⌥⌘K`, or **Lock Keyboard** |
| Unlock | `⌥⌘K` again, or **Unlock** |
| Follow a song | **Follow a Song** — Off by default. Five nursery songs on Z X C V B |
| Hear the melody | **Hear Song** (only while a song is on) |
| About | **About Mr.Blobsky** |
| Record a sound | **Record a Sound…** — one short clip becomes every key |
| Use that clip | **Use My Sound** / **Use Built-in Sounds** |
| Quit | **Quit Mr.Blobsky** |

Keyboard lock needs **Accessibility** and sometimes **Input Monitoring**. macOS
will prompt; you can also use **Allow Keyboard Access…**. Until those are on,
the overlay still appears but other apps can still receive keys.

While locked, mouse and trackpad clicks are also contained by the overlay. A
deliberate click makes one surprise; resting a hand on the trackpad does nothing.

There is no Dock icon. Look for the piano-keys icon in the menu bar. It turns
into a lock while a session is active.

## MVP scope

- Menu-bar agent, no Dock icon
- Simple global hotkey (`⌥⌘K`) to lock the keyboard
- Full-screen overlay of the last pressed key
- Polyphonic synthesized audio, or a recording you make
- Record a short clip and hear it pitched across the keyboard

## Later, maybe

A configurable hotkey.
