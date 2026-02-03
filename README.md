# Bufo Stickers for iMessage

An iMessage sticker app with **search functionality** containing 1,661 bufo (frog) emojis!

## Features

- **Search**: Type to filter stickers by name (e.g., "coffee", "sleep", "hug", "sad")
- **1,661 stickers**: All the bufo emojis you could ever need
- **Animated GIFs**: Includes animated stickers
- **Fast scrolling**: Optimized collection view with sticker caching

## Installation Instructions

### Prerequisites
- Mac with Xcode 15+ installed
- iPhone connected to your Mac via USB
- Apple Developer account (free account works for personal device)

### Steps to Install

1. **Open the project in Xcode:**
   ```bash
   open BufoStickers/BufoStickers.xcodeproj
   ```

2. **Configure signing:**
   - Select the project in the navigator (blue icon at top)
   - Select the "BufoStickers" target
   - Go to "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your Team (your Apple ID)
   - **Repeat for "MessagesExtension" target**

3. **Connect your iPhone:**
   - Plug your iPhone into your Mac with a USB cable
   - Trust the computer on your iPhone if prompted

4. **Select your device:**
   - In Xcode's toolbar, click on the device selector (next to the scheme)
   - Choose your connected iPhone

5. **Build and Run:**
   - Press `Cmd + R` or click the Play button
   - Wait for the build and installation to complete
   - On first run, you may need to trust the developer certificate on your iPhone:
     - Go to Settings > General > VPN & Device Management
     - Tap on your developer account
     - Tap "Trust"

6. **Use in iMessage:**
   - Open the Messages app on your iPhone
   - Start a conversation
   - Tap the Apps button (grid icon) next to the text field
   - Find "Bufo Stickers" in your apps
   - **Use the search bar to find stickers by name!**
   - Tap any sticker to send it

## Search Tips

The sticker names are descriptive, so try searching for:
- Emotions: "happy", "sad", "angry", "love", "cry"
- Actions: "hug", "wave", "sleep", "dance", "work"
- Objects: "coffee", "pizza", "computer", "phone"
- Themes: "christmas", "halloween", "birthday"
- And more!

## Project Structure

```
BufoStickers/
├── BufoStickers.xcodeproj
└── MessagesExtension/
    ├── MessagesViewController.swift   # Main UI with search
    ├── Assets.xcassets/               # App icon
    ├── Stickers/                      # All 1,661 sticker images
    └── Info.plist
```

## Credits

Bufo emojis sourced from [all-the-bufo](https://github.com/knobiknows/all-the-bufo) by knobiknows.

> "Bufo also known as Froge or Concerned Frog refers to a set of Discord emotes of a worried or concerned frog expressing various emotions."
