# Deploy and Host Jellyfin + Google Drive

Run a private, open-source, Plex-style media library using Google Drive for the original media files. One Railway container includes Jellyfin, OpenList, OStrm, and Caddy; one persistent volume stores configuration, metadata, artwork, and the generated STRM library.

## About Hosting

Railway runs the combined container and provides HTTPS, a public domain, health checks, logs, and a persistent 5 GB volume. OpenList reads Google Drive through its API, so this setup does not require a privileged FUSE mount. Playback traffic passes through Railway and is billed as outbound network usage.

## Why Deploy

- One service, domain, volume, and deploy button.
- Automatic movie and TV identification, corrected display names, posters, summaries, cast, years, and genres through Jellyfin's metadata providers.
- Scheduled Drive scanning and lightweight STRM generation through OStrm.
- Pinned, checksum-verified open-source components and automatically generated secrets.
- Original video files remain in Google Drive instead of consuming Railway volume space.

## Common Use Cases

- A personal movie or television library stored in Google Drive.
- A self-hosted alternative to Plex with automatic metadata.
- A remotely accessible Jellyfin server without maintaining a VPS.
- Scheduled catalog updates when media is added to Drive.

## Dependencies for Jellyfin + Google Drive

### Deployment Dependencies

- A Railway account with enough compute and outbound-transfer allowance. About 2 GB of memory is recommended.
- A Google account and Drive content you are authorized to store and stream.
- The public `ghcr.io/youssefsiam38/jellyfin-drive-railway:1.0.2` image.
- No external database and no privileged container.

### Included Applications

- Jellyfin 12.0
- OpenList 4.2.6
- OStrm 2.6.0
- Caddy

## After Deploying

Let `https://YOUR-DOMAIN` be the generated Railway domain.

1. Open `/openlist/` and sign in as `admin` with the generated `OPENLIST_ADMIN_PASSWORD` variable.
2. Add Google Drive using the [official OpenList guide](https://doc.oplist.org/guide/drivers/google_drive).
3. Open `/`, create the OStrm account, then add OpenList as `http://127.0.0.1:5244/openlist`. Set STRM Base URL to `https://YOUR-DOMAIN`.
4. Create a scheduled OStrm task for the Drive media folder.
5. Open `/jellyfin/`, complete the wizard, and add `/data/media` as the Movies or Shows library.

See the [project README](https://github.com/youssefsiam38/jellyfin-drive-railway) for full setup, limitations, local testing, and licenses.
