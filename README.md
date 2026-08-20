# Lapki

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

Open `Lapki.xcodeproj` in Xcode, pick the **Lapki** scheme, press Run.

For an App Store Connect archive, use the latest **stable** Xcode from the Mac
App Store. A beta archive is rejected unless Apple has explicitly listed that
exact seed as accepted in App Store Connect's **News and Updates**. After
installing the supported Xcode, select it and confirm the version before
archiving:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

The version output must not identify the archive toolchain as beta. Rebuild and
upload a new archive after switching; an archive produced by a rejected beta
cannot be made eligible afterward. See Apple's [Xcode release
notes](https://developer.apple.com/documentation/xcode-release-notes) and [App
Store Connect release notes](https://developer.apple.com/help/app-store-connect/release-notes/).

Or from the repo root:

```sh
xcodebuild -scheme Lapki -destination 'platform=macOS' build
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
| Trackpad movement | Paints a colorful magic-wand trail |
| Trackpad click/tap | A rotating surprise sound and sticker burst at the wand |

Any leftover key still makes a sound from its key code, so a full-size keyboard is covered too.

## Menu bar & lock

| Action | How |
| --- | --- |
| Lock + unlimited play | `⌥⌘K`, or **Lock Keyboard** |
| Lock + two-minute play | `⌥⌘T`, or **Lock for 2-Minute Play** |
| Unlock | `⌥⌘K` again, or **Unlock** |
| Follow a song | `⌥⌘1` through `⌥⌘5`, or **Follow a Song** — five nursery songs on Z X C V B |
| Play the selected melody | `⌥⌘P`, or **Play Song** (only while a song is on) |
| About | **About Lapki** |
| Record a sound | **Record a Sound…** — one short clip becomes every key |
| Use that clip | **Use My Sound** / **Use Built-in Sounds** |
| Quit | **Quit Lapki** |

Keyboard lock needs **Accessibility** and sometimes **Input Monitoring**. macOS
will prompt; you can also use **Allow Keyboard Access…**. Until those are on,
the overlay still appears but other apps can still receive keys.

While locked, mouse and trackpad clicks are also contained by the overlay.
Moving paints a short sparkle trail, and a deliberate click makes one surprise
at the wand. Resting a hand on the trackpad does nothing.

The optional two-minute mode limits play, not safety: when time runs out, the
keyboard and pointer stay contained, songs and normal sounds stop, and the cat
says **NOPE!** until a parent unlocks with `⌥⌘K` or the menu.

Song shortcuts follow the menu order: `⌥⌘1` Mary Had a Little Lamb, `⌥⌘2`
Hot Cross Buns, `⌥⌘3` Jingle Bells, `⌥⌘4` Rain Rain Go Away, and `⌥⌘5` The
Farmer in the Dell. Each shortcut selects the song and opens the locked play
screen ready to follow along. The number shortcuts also switch songs immediately
while the play screen is already locked. Starting unlimited or two-minute play
normally clears the previous song and returns to free play.

There is no Dock icon. Look for the piano-keys icon in the menu bar. It turns
into a lock while a session is active.

## MVP scope

- Menu-bar agent, no Dock icon
- Simple global hotkey (`⌥⌘K`) to lock the keyboard
- Full-screen overlay of the last pressed key
- Polyphonic synthesized audio, or a recording you make
- Record a short clip and hear it pitched across the keyboard; recording again replaces the previous clip

## Later, maybe

A configurable hotkey.
