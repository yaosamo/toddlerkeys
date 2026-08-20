# Mr.Blobsky Publishing Kit

## Submission status: blocked for the Mac App Store

This repository now contains the metadata, privacy answers, review notes, icon, support page, release version, and verification checklist that can be prepared locally. **Do not upload the current product to the Mac App Store yet.**

Apple requires App Sandbox for Mac App Store apps. Mr.Blobsky's defining behavior uses macOS Accessibility and a system-level event tap to contain keyboard and pointer input outside its own process. Apple lists accessibility APIs for assistive apps among technologies incompatible with App Sandbox. Turning the sandbox on would produce a build whose core keyboard-lock promise does not work; leaving it off fails Mac App Store validation.

The unchanged product can instead be distributed as a Developer ID-signed and notarized app outside the store. The two honest paths are:

1. **Recommended for the current product:** ship a Developer ID-notarized download.
2. **Mac App Store redesign:** remove the system-wide keyboard/pointer lock and reposition Mr.Blobsky as an in-app-only toy, then enable App Sandbox and test every interaction again.

The locally verified Release build is signed with the installed Apple Development certificate. It is a test artifact, not a distributable release; it must be rebuilt with the distribution identity for the chosen path.

Official references: [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox), [protecting user data with App Sandbox](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox), and [configuring the macOS App Sandbox](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox).

## Release identity

| Field | Value |
| --- | --- |
| App name | `Mr.Blobsky` |
| Bundle ID | `com.yaosamo.mrblobsky` |
| Version | `1.0.0` |
| Build | `3` |
| Primary category | Entertainment |
| Suggested secondary category | Education |
| Copyright | `2026 Yaosamo` |
| Privacy policy URL | `https://github.com/yaosamo/toddlerkeys/blob/main/PRIVACY.md` |
| Support URL | `https://github.com/yaosamo/toddlerkeys/blob/main/SUPPORT.md` |
| Marketing URL | `https://github.com/yaosamo/toddlerkeys` |
| SKU | **Owner must choose a permanent private value**, for example `MRBLOBSKY-MAC-001` |

Before entering these URLs in App Store Connect, merge and publish `PRIVACY.md` and `SUPPORT.md` on the public default branch, then open each URL in a signed-out browser.

## Copy-paste English metadata

### Name

```text
Mr.Blobsky
```

### Subtitle

```text
Music for little hands
```

### Promotional text

```text
Turn curious key presses into friendly music, silly sounds, colorful trails, and blob-cat surprises—with an optional two-minute parent timer.
```

### Description

```text
Mr.Blobsky turns a Mac keyboard and trackpad into a cheerful musical playground.

Press almost any key to hear a friendly note or silly sound while animated blob-cat stickers bounce across the screen. Move the trackpad to paint a colorful trail, or click for a surprise.

Choose from five familiar follow-along melodies, then play the selected song whenever you like. You can also record one short sound and let Mr.Blobsky transform it across the keyboard. Recording again simply replaces the old clip.

For focused parent time, start an optional two-minute play session. When time is up, the music stops and Mr.Blobsky says “NOPE!” until a parent uses the unlock shortcut.

Highlights:
• Friendly pentatonic notes and playful sound effects
• Five follow-along nursery melodies
• Colorful trackpad trails and animated sticker surprises
• Optional local microphone recording
• Two-minute play timer
• Parent lock/unlock shortcut
• No accounts, ads, analytics, tracking, or network features

Mr.Blobsky lives in the menu bar and needs macOS Accessibility permission for its keyboard containment feature. Some macOS versions may also request Input Monitoring. A microphone permission is requested only if you choose to record a sound.
```

### Keywords

```text
toddler,keyboard,music,sounds,stickers,playtime,parent,melody,nursery,rhythm
```

The keywords are comma-separated and under App Store Connect's 100-byte limit. Product-page field guidance is in Apple's [product page documentation](https://developer.apple.com/app-store/product-page/).

### What's New for 1.0.0

```text
Meet Mr.Blobsky: playful keyboard sounds, colorful trackpad magic, five follow-along songs, your own recorded sound, and an optional two-minute parent timer.
```

## App privacy answers

Use these answers in App Store Connect:

| Question | Answer |
| --- | --- |
| Does this app collect data? | No, Data Not Collected |
| Is data used to track users? | No |
| Does the app contain third-party analytics or advertising SDKs? | No |
| Is audio transmitted off the device? | No |
| Is keyboard input stored or transmitted? | No |

Apple defines collection around transmitting data off-device for access beyond the immediate request. Mr.Blobsky processes key events in memory and stores an optional recording only on the user's Mac, so that local activity is not declared as collected. The repository's `PrivacyInfo.xcprivacy` declares no tracking, collected-data types, tracking domains, or accessed API types. Recheck these answers if networking, telemetry, crash reporting, cloud sync, or another SDK is added. See [App privacy details](https://developer.apple.com/app-store/app-privacy-details/) and [privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files).

## Age rating and audience

Suggested age-rating questionnaire answers for the current content:

- All content-frequency questions: **None**.
- Parental controls: **Yes** if App Store Connect asks whether the app includes controls that let a parent limit use; the app has a parent unlock chord and two-minute timer.
- Unrestricted web access, user-generated content, messaging, advertising, purchases, gambling, contests, violence, profanity, horror, medical, alcohol/tobacco/drugs, sexual content: **No/None**.

The resulting rating is expected to be the lowest general rating, but App Store Connect calculates the final rating. Verify the questionnaire rather than copying an assumed badge. See [Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating).

Do **not** select **Made for Kids** casually. Apple treats that choice as a lasting product decision with additional category, link, analytics, and advertising rules. Mr.Blobsky can use the Entertainment category and family-friendly copy without making that irreversible selection. If you intentionally choose the Kids category, review [Apple's kids app requirements](https://developer.apple.com/kids/) first and revise the metadata and every external link accordingly.

## Export compliance

The app does not implement or bundle encryption. `ITSAppUsesNonExemptEncryption` is set to `NO` for Debug and Release. Answer that the app does not use non-exempt encryption. Reassess if network security, custom cryptography, authentication, or encrypted storage is added. Apple's distribution preparation guide covers export-compliance information: [Preparing your app for distribution](https://developer.apple.com/documentation/Xcode/preparing-your-app-for-distribution).

## Content rights

Answer **Yes** when asked whether the app has rights to its content, after confirming the repository license notices are included in the distributed product and store record where appropriate.

Blob-cat artwork is attributed in `THIRD_PARTY_BLOBCATS_LICENSE` and documented as Apache 2.0 material from DuckOfDisorder/BlobCats, derived from Google blob art, plus identified Slackmoji blob-cat assets. Keep that notice with every release and do a final asset-by-asset rights audit before submission.

## App Review notes — copy and paste

```text
Mr.Blobsky is a menu-bar app with no Dock icon and no account or network service.

To begin, click the cat icon in the menu bar and choose Lock Keyboard, or press Option-Command-K. Press the same Option-Command-K shortcut again to unlock. Option-Command-T starts the optional two-minute session. Option-Command-1 through Option-Command-5 select a follow-along song, and Option-Command-P plays the selected melody.

The keyboard containment feature requires Accessibility permission and may also require Input Monitoring depending on macOS. These permissions are used only to prevent playful key presses from reaching other apps and to turn those presses into local sounds and animations. Key events are not saved or transmitted.

Microphone permission is optional and is requested only after the reviewer chooses Record a Sound. The recording is stored locally in Application Support, is never uploaded, and a new recording replaces the previous one.

The app contains no login, purchases, ads, analytics, tracking, or network functionality.

IMPORTANT DISTRIBUTION NOTE: the current build intentionally does not enable App Sandbox because its system-wide Accessibility/event-tap containment feature is incompatible with sandboxing. This build should not be submitted to the Mac App Store unless that core feature is redesigned or Apple provides an approved entitlement path.
```

## Screenshots

Apple accepts **1–10** macOS screenshots per localization. Screenshots must have no transparency and use a supported 16:10 size: `1280×800`, `1440×900`, `2560×1600`, or `2880×1800`. See [macOS screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) and [uploading screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots).

Recommended five-shot story:

1. Free-play screen with the blob-cat face, keyboard, and several stickers.
2. Trackpad trail in motion with a surprise sticker near the pointer.
3. Follow-a-song screen with one of the five melodies selected.
4. Record-a-sound window showing the simple replaceable recording flow.
5. Two-minute session expired with the funny **NOPE!** response and parent unlock guidance.

Capture these manually on a clean desktop at one supported size. Avoid personal menu-bar items, notifications, filenames, or another app's content. The required marketing icon is already at `AppStore/AppIcon-1024.png` and is 1024×1024 with no alpha; the asset catalog contains the matching production icon set.

## Mac App Store submission checklist

Only use this checklist after resolving the sandbox incompatibility:

- [ ] Decide whether to remove/redesign system-wide input containment.
- [ ] Enable App Sandbox and add only the entitlements the redesigned app actually needs.
- [ ] Re-test keyboard, pointer, microphone, saved recording, songs, timer, and every hotkey in a Release build.
- [ ] Create the App Store Connect app record using the bundle ID and owner-chosen SKU.
- [ ] Confirm the Paid Apps agreement, tax, and banking status if the app will be paid or offer purchases.
- [ ] Install a valid Apple Distribution certificate and Mac App Store provisioning profile for team `6J57A4298A`.
- [ ] Merge and publish the privacy and support pages; verify their URLs while signed out.
- [ ] Capture and upload at least one screenshot at an accepted size.
- [ ] Enter metadata, category, age-rating, privacy, export-compliance, and content-rights answers.
- [ ] Archive the Release build in Xcode, validate it, and upload it to App Store Connect.
- [ ] Test the uploaded build through TestFlight for Mac.
- [ ] Select the build, complete App Review contact information, answer every compliance prompt, and submit.

App Store Connect field requirements and the submission flow are documented in [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information), [platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information), and [Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/). Review the current [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) immediately before submission.

## Developer ID distribution checklist — viable current path

The current machine has an Apple Development identity but no Developer ID Application identity. To distribute the working product outside the Mac App Store:

- [ ] Create or install a **Developer ID Application** certificate for the configured team.
- [ ] Keep Hardened Runtime enabled and keep the microphone entitlement.
- [ ] Archive a Release build signed with Developer ID Application.
- [ ] Export the signed app from Xcode.
- [ ] Submit the app or packaged disk image to Apple's notary service with `notarytool`.
- [ ] Wait for acceptance, inspect the notary log if rejected, then staple the ticket with `stapler`.
- [ ] Verify with `codesign --verify --deep --strict --verbose=2` and `spctl --assess --type execute --verbose=4`.
- [ ] Publish the notarized artifact from an HTTPS download page alongside the privacy policy, support page, license notices, version, and checksum.
- [ ] Test a fresh download on another Mac before announcing the release.

## Remaining owner-supplied items

- Distribution decision: Developer ID release or sandbox-compatible redesign.
- Apple Developer/App Store Connect account roles and agreements.
- Apple Distribution or Developer ID certificate, as appropriate.
- Permanent SKU and App Review contact details.
- Price, availability, territories, and release method.
- Final age-audience decision, including whether to enter the Kids category.
- Manually captured screenshots.
- Final asset-rights confirmation.
- Public, merged support and privacy URLs.
