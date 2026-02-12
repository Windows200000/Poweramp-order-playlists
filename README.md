## Instructions
- Run with [Termux](https://play.google.com/store/apps/details?id=com.termux)
    - [How to setup storage access](https://wiki.termux.com/wiki/Termux-setup-storage)
- `curl -O https://raw.githubusercontent.com/Windows200000/Poweramp-order-playlists/refs/heads/main/Playlist_order_time.sh`
- `./Playlist_order_time.sh ./storage/shared/Path/To/Playlistfolder`.
- Sort in PowerAmp "By date added/modified" without "Reverse"

> [!WARNING]
> Backup your existing playlists just in case, tho I can't see how it could corrupt them.

> [!NOTE]
> I highly suggest creating the space separated list with your favorite AI chatbot and selecting text from screenshots with your desired order. You can use the Smasumg spen for this, Circle to Search etc.

## AI use
The script is made mostly with AI + some tweaks and fixes to make it work and easier to use.

Enjoy ;)

## Change log

### 23.6.2025

- Now supports .m3u8 files (the ones PowerAmp generates when exporting playlists)

### 12.2.2026
- Now stores playlist order for easier recovery
- sets future dates for no required wait after modification
- with the store function, new playlists can be easily added to the desired position
