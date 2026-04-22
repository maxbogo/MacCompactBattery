<p align="center">
  <img src="MacCompactBattery/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" alt="MacCompactBattery icon" width="160" />
</p>

# MacCompactBattery

Small macOS menu bar app that displays the current internal battery percentage as a compact numeric status item while hiding the battery icon to save space in the menu bar.

_Default macOS icon (top) vs. MacCompactBattery (bottom)_

![Before and after comparison](assets/before-after-stacked.png)


## Install: Build from Source

```sh
xcodebuild -scheme MacCompactBattery -configuration Release build
```

## Status Examples

The menu bar item changes color to make battery state easier to read at a glance:

| Status | Preview | Explanation |
| --- | --- | --- |
| Charging | ![Charging status](assets/status-charging.png) | The percentage is shown in green while the Mac is connected to power and actively charging. |
| Low battery | ![Low battery status](assets/status-low-battery.png) | The percentage switches to red when the battery level drops below 20%. |
| Normal | ![Normal status](assets/status-default.png) | The percentage is shown in the default light color during regular battery use. |

## Requirements

- macOS 13.0 or later
- Xcode 16 or later

## License

Released under the [MIT License](LICENSE).
