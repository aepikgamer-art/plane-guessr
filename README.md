# PlaneGuessr

GeoGuessr, but for planes. You get a real aircraft photo (live from
[jetapi.dev](https://www.jetapi.dev), which scrapes JetPhotos + FlightRadar24),
and you guess which airport it was taken at by dropping a pin on an Apple Map.
Closer pin = more points. Liquid Glass UI on iOS 26.

## Build the IPA (no Mac, no Xcode on your machine)

1. Push to GitHub. The **Build unsigned IPA** action runs on every push.
2. Download the `PlaneGuessr-unsigned-ipa` artifact, or grab the IPA from the
   [Releases](https://github.com/aepikgamer-art/plane-guessr/releases) page
   (push a `v*` tag to publish one).
3. Sideload `PlaneGuessr.ipa` with **Sideloadly** or **AltStore** using a free
   Apple ID (7-day resign, 3-app limit on free accounts).

> The build runs on GitHub's free `macos-latest` runner — you never own a Mac
> or open Xcode. The IPA is **unsigned**: your sideloading tool signs it with
> your own (free) Apple ID at install time.

## Install with LiveContainer (AltDirect)

The repo ships an AltStore source (`altsource.json`) served via GitHub Pages.

**One-tap link (opens straight into LiveContainer):**

https://altdirect.app/?url=https%3A%2F%2Faepikgamer-art.github.io%2Fplane-guessr%2Faltsource.json&r=livecontainer

Or use the plain page and pick your app:
https://altdirect.app/?url=https://aepikgamer-art.github.io/plane-guessr/altsource.json

1. Make sure GitHub Pages is enabled: Settings → Pages → Deploy from a branch
   → `main` / `(root)`. The source lands at
   https://aepikgamer-art.github.io/plane-guessr/altsource.json
2. Open the AltDirect link above on your iPhone.
3. LiveContainer opens → add the source → install PlaneGuessr.

## Run it locally (only if you want to)

`brew install xcodegen && xcodegen generate` then open the generated project.

## How scoring works

`points = 5000 * 2^(-km/250)` — a 1 km guess is ~5000 pts, 250 km ~2500,
2000 km ~22. Streak counter bumps when you land within 50 km.
