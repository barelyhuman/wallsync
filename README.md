# WallSync

> Automatic wallpaper sync for macOS 13+

![](/static/preview.png)

## Why?

MacOS doesn't come with an option to set the wallpaper for more than one screen at the same time. WallSync runs in the background and automatically syncs your wallpaper across all displays whenever you change your wallpaper or connect a new screen.

Also because of [this](https://justforfunnoreally.dev)

## How it works

WallSync runs as a background service that:

- Automatically syncs wallpaper across all displays when you change your wallpaper
- Detects when a new screen is connected and syncs the wallpaper to it
- No manual intervention needed - just set it and forget it

## Installation

Because the app isn't signed with an apple account, you'll have to do a minor modification **after copying it to the Applications folder** by running the following in your `Terminal`.

```sh
xattr -c /Applications/wallsync.app
```

> This is normal for apps distributed outside the App Store, if you need signed apps, you might need to help me get a paid apple developer account.

After installation, launch the app once to start the background service. It will continue running automatically

## Releases

Just download the packages from the [releases](https://github.com/barelyhuman/wallsync/releases)

## LICENSE

[MIT](LICENSE)
