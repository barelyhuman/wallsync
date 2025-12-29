# WallSync

> Minimal wallpaper switcher for macOS

![](/static/preview.png)

## Why? 

MacOS doesn't come with an option to set the wallpaper for more than one screen at the same time, this app wishes to accomplish that while being minimal.

Also because of [this](https://justforfunnoreally.dev)

## Installation 

Because the app isn't signed with an apple account, you'll have to do a minor modification to the app **after copying it to the Applications folder** by running the following in your `Terminal`.

```sh
xattr -c /Applications/wallsync.app
```

> This is normal for apps distributed outside the App Store, if you need signed apps, you might need to help me get a paid apple developer account. 


### Caveats 
- Both monitors need to be on the default workspaces and not in full screen apps as that doesn't work with the screen api being used internally with the app. 

## Releases

Just download the packages from the [releases](https://github.com/barelyhuman/wallsync/releases)

## LICENSE

[MIT](LICENSE)
