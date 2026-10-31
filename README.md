# FastRider

**English** · [简体中文](README.zh-CN.md)

[![Fast Rider: English feature callouts around the Edge 840 day riding dashboard, on a pale road background](store/campaign/v0.4.13/upload/01-hero-en.png)](#download)

**Power, heart rate, lap stats and your ride essentials — on one screen.**

A free, open-source Connect IQ data field for **12 Garmin Edge models**. Built for readable ride data, steady Z2 sessions and long threshold intervals.

**[Download](#download)** · [Install](#install) · [Controls](#controls) · [Build from source](#develop) · [Contribute](#contribute)

## For riders

- **Your key numbers, together.** Big heart rate and power, rear gear, cadence, grade, speed and All/current-lap statistics.
- **Your effort, color coded.** Numbered zone badges, tapered progress bars and matching power-graph colors.
- **A touch bell.** Double-tap the left side for a two-second, three-strike electronic bell effect on supported touch models.
- **Two views, automatically.** Live metrics while riding; a whole-ride summary when paused or stopped.
- **Ready for day and night.** Follows the Edge data-field background, with bright colors on black at night.

<table>
<tr>
<td width="50%"><a href="store/campaign/v0.4.13/upload/04-screen-01-ride-day.png"><img src="store/campaign/v0.4.13/upload/04-screen-01-ride-day.png" width="440" alt="Latest Edge 840 live dashboard"></a></td>
<td width="50%"><a href="store/campaign/v0.4.13/upload/04-screen-02-touch-bell.png"><img src="store/campaign/v0.4.13/upload/04-screen-02-touch-bell.png" width="440" alt="Two taps trigger the two-second electronic bell"></a></td>
</tr>
</table>

### Power graph: Z2 + threshold

**Z2 stays blue; threshold stays orange.** Z2 spans above 55% through 75% FTP, and Z4 spans above 90% through 105%. See the Z2 ceiling, FTP guide and native lap boundaries across 5m, 20m or All. The graph supports reviewing steady endurance work and sessions such as 3 × 20 minutes; it does not run or prescribe a workout.

### Your ride, when you pause

Stop the timer or trigger Auto Pause to see elapsed time, a **top-right clock**, current/average heart rate, average power, local NP, distance, ascent, average cadence and average speed. Short metric names sit above the values; small units follow the numbers. Valid navigation distance remains blue in parentheses. Resume to return to your selected ride views. Button-only models also switch automatically.

NP needs 30 seconds of observed power, includes valid zero watts and excludes pauses. Mid-ride loading or missing samples displays **NP est**, with a small w suffix. NP and lap-average power are locally estimated and may differ from Garmin statistics. There is no Moving field.

<table>
<tr>
<td width="50%"><a href="store/campaign/v0.4.13/upload/04-screen-03-auto-summary.png"><img src="store/campaign/v0.4.13/upload/04-screen-03-auto-summary.png" width="440" alt="Paused summary with short metric names and inline units"></a></td>
<td width="50%"><a href="store/campaign/v0.4.13/upload/04-screen-04-day-night.png"><img src="store/campaign/v0.4.13/upload/04-screen-04-day-night.png" width="440" alt="Current interface in the high-contrast night theme"></a></td>
</tr>
</table>

### Read your effort. Make it yours.

Power colors: **gray Z1/Z3 · blue Z2 · orange Z4 · purple Z5 · red Z6/Z7**. Heart-rate zones are independent, while cadence and grade have their own alerts. The solid part of each tapered gauge shows your position inside the current zone.

Touch models switch power between 3s/10s, statistics between All/current lap, and the graph between 5m/20m/All. Button-only 530/540/550 use the default 3s/All/5m view and automatic paused summary, without touch controls or the bell.

*All device images use the official Edge 840 exterior and actual native UI captures with synthetic example data. Open any image to inspect it. [Store copy and full upload kit](store/campaign/v0.4.13/README.md) · [Current UI validation](docs/validation/clock/v0.4.13/README.md).*

## Download


<!-- downloads:start -->
Current version: **v0.4.13**. No SDK or Java needed to install. Choose a PRG to copy directly, or a ZIP with the same program, installation instructions and licenses.

| Device | Native resolution | Interaction | Direct PRG | ZIP |
| --- | --- | --- | --- | --- |
| Edge 530 | 246×322 | Fixed default view | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge530/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge530/FastRider-0.4.13-edge530.zip) |
| Edge 540 | 246×322 | Fixed default view | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge540/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge540/FastRider-0.4.13-edge540.zip) |
| Edge 550 | 420×600 | Fixed default view | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge550/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge550/FastRider-0.4.13-edge550.zip) |
| Edge 830 | 246×322 | Touch controls + bell | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge830/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge830/FastRider-0.4.13-edge830.zip) |
| Edge 840 | 246×322 | Touch controls + bell | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge840/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge840/FastRider-0.4.13-edge840.zip) |
| Edge 850 | 420×600 | Touch controls + bell | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge850/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge850/FastRider-0.4.13-edge850.zip) |
| Edge 1030 | 282×470 | Touch controls + bell | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1030/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1030/FastRider-0.4.13-edge1030.zip) |
| Edge 1030 Bontrager | 282×470 | Touch controls + bell | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1030bontrager/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1030bontrager/FastRider-0.4.13-edge1030bontrager.zip) |
| Edge 1030 Plus | 282×470 | Touch controls + bell | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1030plus/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1030plus/FastRider-0.4.13-edge1030plus.zip) |
| Edge 1040 | 282×470 | Touch controls + bell | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1040/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1040/FastRider-0.4.13-edge1040.zip) |
| Edge 1050 | 480×800 | Touch controls + bell | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1050/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1050/FastRider-0.4.13-edge1050.zip) |
| Edge 1060 | 480×800 | Touch controls + bell | [PRG](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1060/FastRider.prg) | [ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/edge1060/FastRider-0.4.13-edge1060.zip) |

[All devices ZIP](https://github.com/zhilichen/garmin-fast-rider/raw/refs/heads/main/releases/v0.4.13/FastRider-0.4.13.zip) · [SHA256 checksums](releases/v0.4.13/SHA256SUMS) · [Release manifest](releases/v0.4.13/manifest.json)
<!-- downloads:end -->

Choose the file for your **exact device model**. Solar variants follow the matching Garmin device package. Every model uses a **one-field, full-screen** activity page.

These direct downloads are ready to sideload and include the latest changes. The [Connect IQ listing](https://apps.garmin.com/apps/ba487f91-82ad-4baa-94f0-9002f86d6a53) shows Garmin Store availability; sideload and Store versions may differ.

## Install

1. Download your model's **PRG**, or unzip its **ZIP** and find `FastRider.prg` inside the model folder.
2. Connect the Edge in USB/computer mode. Copy that file to the device's internal `GARMIN/APPS/` folder. On macOS, use an MTP-capable file-transfer application if the Edge is not shown as a mounted drive.
3. Disconnect USB. In your cycling profile, add/select **Connect IQ → FastRider** on a data page and set its layout to **one field**.

For an update, replace the existing file **using its existing filename**. Early installations may use `SUMMIT.PRG`; rename the new download to that name before replacing it. New installations use `FastRider.prg`.

Pair the sensors that supply the values you want to see. Power, heart rate, cadence and rear gear require compatible data sources; rear gear needs electronic-shifting data. Missing values display dashes. Current units are **mi, mph and ft**.

## Controls

The initial view is **3s power / All ride / 5m graph**.

| Touch area | Gesture | Result |
| --- | --- | --- |
| Top-right power | Tap | 3s ↔ 10s average |
| Right-side statistics | Tap | All ride ↔ current lap |
| Graph or its range label | Tap | 5m → 20m → All |
| Left heart-rate/live-data area | Double-tap | Two-second electronic bell |

Touch models select the newest lap after a native manual or automatic lap boundary. Garmin begins the activity in lap 1; the first completed lap starts lap 2. FastRider initially shows **All**.

**Edge 530, 540 and 550 keep the fixed 3s / All / 5m view.** They have no touch controls or electronic bell; lap boundaries still appear in the graph. Bell sound and loudness depend on device tone support. The effect uses device tones, not Garmin's native bike-bell function.

[View the bell](store/campaign/v0.4.13/upload/04-screen-02-touch-bell.png) · [View the riding dashboard](store/campaign/v0.4.13/upload/04-screen-01-ride-day.png)

### What the numbers mean

| Value | Source and behavior |
| --- | --- |
| FTP / heart-rate zones | Cycling profile when available, with app-setting fallbacks. Default fallback FTP: 250 W. |
| Power | Valid zero watts are included. Missing, paused or interrupted samples do not reuse an old average. |
| All / Lap average power | All prefers Garmin's ride average. Lap is estimated locally and can differ from Garmin's own lap statistic. |
| Time | Statistics exclude paused time; the graph's elapsed-time axis includes it. |
| Grade / remaining distance | Grade is estimated from altitude and distance. Remaining distance appears when Garmin supplies a valid named navigation destination. |
| History | Starts when the field runs. Earlier ride samples, future course elevation and an already-started lap's full state cannot be reconstructed. |

### See your device

The layout uses four display profiles, with larger numeric fonts on larger screens. **All 12 models have native simulator captures**; this is not a claim of physical-device testing on every model.

<details>
<summary><strong>Expand the 12-model native screenshot gallery</strong></summary>

Gallery updated for **v0.4.11**: native captures for all 12 models, with day/night riding and paused views across all four screen resolutions in the validation notes.

<!-- screenshots:start -->
Native day-mode simulator captures, using synthetic data. Capture versions are listed in the validation notes below. Previews share a display width while keeping their aspect ratio; open an image to inspect native pixels.

| Edge 530 | Edge 540 | Edge 550 |
| --- | --- | --- |
| <a href="docs/validation/screens/edge530.png"><img src="docs/validation/screens/edge530.png" width="246" alt="Edge 530 246x322"></a> | <a href="docs/validation/screens/edge540.png"><img src="docs/validation/screens/edge540.png" width="246" alt="Edge 540 246x322"></a> | <a href="docs/validation/screens/edge550.png"><img src="docs/validation/screens/edge550.png" width="246" alt="Edge 550 420x600"></a> |

| Edge 830 | Edge 840 | Edge 850 |
| --- | --- | --- |
| <a href="docs/validation/screens/edge830.png"><img src="docs/validation/screens/edge830.png" width="246" alt="Edge 830 246x322"></a> | <a href="docs/validation/screens/edge840.png"><img src="docs/validation/screens/edge840.png" width="246" alt="Edge 840 246x322"></a> | <a href="docs/validation/screens/edge850.png"><img src="docs/validation/screens/edge850.png" width="246" alt="Edge 850 420x600"></a> |

| Edge 1030 | Edge 1030 Bontrager | Edge 1030 Plus |
| --- | --- | --- |
| <a href="docs/validation/screens/edge1030.png"><img src="docs/validation/screens/edge1030.png" width="246" alt="Edge 1030 282x470"></a> | <a href="docs/validation/screens/edge1030bontrager.png"><img src="docs/validation/screens/edge1030bontrager.png" width="246" alt="Edge 1030 Bontrager 282x470"></a> | <a href="docs/validation/screens/edge1030plus.png"><img src="docs/validation/screens/edge1030plus.png" width="246" alt="Edge 1030 Plus 282x470"></a> |

| Edge 1040 | Edge 1050 | Edge 1060 |
| --- | --- | --- |
| <a href="docs/validation/screens/edge1040.png"><img src="docs/validation/screens/edge1040.png" width="246" alt="Edge 1040 282x470"></a> | <a href="docs/validation/screens/edge1050.png"><img src="docs/validation/screens/edge1050.png" width="246" alt="Edge 1050 480x800"></a> | <a href="docs/validation/screens/edge1060.png"><img src="docs/validation/screens/edge1060.png" width="246" alt="Edge 1060 480x800"></a> |

[More states, native captures and validation notes](docs/screenshots.md)
<!-- screenshots:end -->

</details>

## Develop

![FastRider architecture: shared metrics and renderer, four generated display profiles, twelve device builds, then build, VM tests, native screenshots and packaging](docs/media/developer-map.png)

**Change the metrics and design in shared code.** Model-specific differences live in the device catalog; layouts and font resources are generated by display profile. Adding an existing screen size should not require a separate renderer.

### Start locally

Install the official [Connect IQ SDK Manager](https://developer.garmin.com/connect-iq/sdk/), **JDK 17**, Bash and **Python 3.10+**. Download only the Edge device packages you need. The documented build/simulator workflow has been exercised on macOS.

```bash
git clone https://github.com/zhilichen/garmin-fast-rider.git
cd garmin-fast-rider

./scripts/check-env.sh edge840
./scripts/build.sh live edge840
./scripts/run.sh demo edge840
```

The production output is `bin/edge840/FastRider-live.prg`. `demo` uses synthetic data; use `live` to read real activity information. Normal app builds use committed font resources and do not require the marketing-image tools.

The scripts discover the SDK Manager's selected SDK, or accept `CIQ_SDK_PATH`, `CIQ_HOME` and `JAVA_HOME`. The first build creates a local signing key in ignored `.local/developer_key.der`; `CIQ_DEVELOPER_KEY` selects an existing key. Keep the same key for updates. Use your own app ID and key when publishing a separate fork.

### Where to make a change

| Change | Shared source |
| --- | --- |
| Metrics, power windows, lap statistics, history | [source/model](source/model/) |
| Activity sampling and drawing | [FastRiderView.mc](source/app/FastRiderView.mc) |
| Zone colors and alerts | [DisplayRules.mc](source/ui/DisplayRules.mc) |
| Native day/night theme and graph contrast | [DisplayTheme.mc](source/ui/DisplayTheme.mc) |
| Default views, tap regions and lap behavior | [InteractionState.mc](source/ui/InteractionState.mc) |
| Touch/bell or button-only entry points | [source/input](source/input/) |
| Positions and spacing | [design/layout.json](design/layout.json) |
| Models, display profiles and capabilities | [config/devices.json](config/devices.json) |

After layout/catalog changes, run `python3 scripts/generate-project.py`. For a new font size or resolution, run `python3 scripts/generate-fonts.py` first, then regenerate the project. Generated layouts live in `config/display/`; native font resources live in `resources/fonts/`.

### Validate a change

```bash
# SDK-free source, font, download and recorded-image checks
python3 -m pip install -r requirements-dev.txt
python3 scripts/generate-project.py --check
python3 scripts/check-downloads.py
python3 scripts/check-generated-fonts.py
python3 -m unittest discover -s tests/python -v

# Native tests for one target
./scripts/run.sh test edge840

# All configured devices (macOS; close other CIQ simulators first)
source scripts/env.sh
python3 scripts/test-matrix.py
```

For UI changes, build a deterministic capture with `./scripts/build.sh snapshot edge840`, run it in the simulator and export the **native screen**. Also inspect long values, missing sensors and affected display profiles. The approved 840 baseline has 12 view combinations; intentional design changes should update it explicitly.

**v0.4.10**: Large ride distance with mi and remaining miles stacked in a right column. [Distance validation](docs/validation/distance/v0.4.10/README.md).

**v0.4.9**: Right-aligned power Zone badge, full-size three-digit power and automatic four-digit fitting. [Power validation](docs/validation/power/v0.4.9/README.md).

**v0.4.8**: Compact paused-summary labels, larger values and a wider right column for long readings. [Summary validation](docs/validation/summary/v0.4.8/README.md).

**v0.4.7**: Larger raised Zone badges, inline All/Lap time with smaller seconds after one hour, and larger distance. Bounded font/history caches improve legacy runtime memory. [Riding validation](docs/validation/riding/v0.4.7/README.md).

**v0.4.6**: Two-column paused summary with eight ride metrics, time on top and a compact graph. 510 native test executions across 12 models, with unchanged Edge 840 riding pixels. [Summary validation](docs/validation/summary/v0.4.6/README.md).

**v0.4.5**: Larger live numerals and tight vertical labels. 489 native test executions across 12 models; pixels outside the live cells and the stopped view are unchanged. [Live-cell validation](docs/validation/live-cells/v0.4.5/README.md).

**v0.4.4**: Number-only zone badges and tapered solid/hollow gauges. 465 native test executions across 12 models; pixels outside the Zone regions and the stopped view are unchanged. [Zone validation](docs/validation/zones/v0.4.4/README.md).

**v0.4.3**: Dedicated paused/stopped summary, 441 native test executions across all 12 models, and unchanged Edge 840 day/night riding pixels. [Summary validation](docs/validation/summary/v0.4.3/README.md).

**v0.4.2**: 381 native test executions passed across all 12 models. Day/night captures cover four display profiles and the button-only 530; all five day captures match v0.4.1 exactly, including the 840 after switching back from night. [Theme validation](docs/validation/themes/v0.4.2/README.md).

Recorded **v0.4.1** validation: 345 native test executions passed across 12 models, with zero changed pixels in the 12 Edge 840 reference states. [Validation evidence](docs/validation.md) · [CI results](https://github.com/zhilichen/garmin-fast-rider/actions)

### Package a build

```bash
./scripts/build.sh live all
python3 scripts/package.py          # Local dist/ archive
python3 scripts/package.py --publish
python3 scripts/check-downloads.py
```

`--publish` writes versioned files under `releases/` and updates the download/gallery blocks in **both READMEs**. It does not push Git or submit to Garmin. Published version directories are immutable; changed app builds need a new version and validation.

[Detailed development guide (中文)](docs/development.md) · [Architecture notes (中文)](docs/architecture.md) · [Visual source and regeneration](docs/media/README.md)

## Contribute

[Open an issue](https://github.com/zhilichen/garmin-fast-rider/issues) with your device model, firmware/app version, page layout and steps to reproduce. For visual problems, include a screenshot and whether it is from a device or the simulator. Use synthetic fixtures when possible; do not include signing keys or private ride files.

Pull requests should explain the resulting behavior, affected display profiles and validation. Start with [CONTRIBUTING.md](CONTRIBUTING.md); keep metrics, formatting and drawing shared across models.

## License and privacy

Project code: [MIT](LICENSE). Bundled fonts have separate [third-party licenses](THIRD_PARTY_NOTICES.md). The app does not collect or upload data to the developer; see the [privacy policy](PRIVACY.md).

Independent project, not affiliated with Garmin. Garmin retains its device-design and trademark rights. Campaign artwork and editable diagram sources are documented in [visual credits](docs/media/README.md).
