# Jellyfin + Google Drive on Railway

One Railway service containing:

- **Jellyfin 12.0** — Plex-style library, automatic titles, posters, cast, genres, and metadata.
- **OpenList 4.2.6** — accesses Google Drive through its API; no FUSE mount or privileged container.
- **OStrm 2.6.0** — scans OpenList, creates tiny `.strm` files, schedules updates, and can fetch TMDB artwork/NFO files.
- **Caddy** — exposes all three apps through one Railway domain.

All application state and generated library files live on one persistent `/data` volume. The original videos stay in Google Drive.

## Deploy

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/REPLACE_AFTER_PUBLISH)

The template creates one service, one domain, one volume, and random secrets. A 2 GB memory limit is recommended. Railway still carries playback traffic, so its egress charge applies.

Container image: `ghcr.io/youssefsiam38/jellyfin-drive-railway:1.0.0`

## First-time setup

Let `https://YOUR-DOMAIN` be the domain Railway creates.

1. Open `https://YOUR-DOMAIN/openlist/` and sign in as `admin` using the generated `OPENLIST_ADMIN_PASSWORD` variable.
2. In OpenList, add a **Google Drive** storage. Follow the [official Google Drive driver guide](https://doc.oplist.org/guide/drivers/google_drive).
3. Open `https://YOUR-DOMAIN/` and create the OStrm administrator account.
4. In OStrm, add OpenList with URL `http://127.0.0.1:5244/openlist`. Set **STRM Base URL** to `https://YOUR-DOMAIN` so players receive reachable links.
5. Add an OStrm task for the movie or TV folder. Generated files are written under `/data/media`; enable its schedule and optional TMDB scraping.
6. Open `https://YOUR-DOMAIN/jellyfin/`, finish Jellyfin's wizard, and add `/data/media` as the Movies and/or Shows library.
7. Optional: create a Jellyfin API key, then add Jellyfin to OStrm with API URL `http://127.0.0.1:8096/jellyfin`. OStrm can then refresh the library after every scan.

Jellyfin's built-in TMDB/OMDb providers supply the corrected display name, poster, synopsis, cast, year, and genre. OStrm's TMDB/AI scraping is useful for unusually messy filenames but is not required for normally named releases.

## Paths

| URL/path | Purpose |
| --- | --- |
| `/` | OStrm indexing and scraping UI |
| `/openlist/` | OpenList and Google Drive configuration |
| `/jellyfin/` | Jellyfin setup and playback |
| `/data/media` | Shared generated STRM/NFO/artwork library |
| `/data` | Railway persistent-volume mount |

## Run locally

```bash
docker compose up --build
./tests/smoke.sh
```

Open <http://localhost:3000>. Change both example secrets in `compose.yaml` before exposing it publicly.

## Important limitations

- This does not mount Google Drive. OpenList accesses it over the Drive API, which works in Railway's unprivileged containers.
- Playback goes Google Drive → Railway → viewer. Railway bills outbound traffic at its current egress rate.
- Google Drive quotas and provider policies still apply. Use media you are authorized to store and stream.
- Railway volumes attach to one service and cannot be shared. That is why all components run in one container.
- Transcoding is CPU-intensive and Railway has no consumer GPU option. Prefer clients that can direct-play your formats.

## Version and license notes

The Docker build pins the upstream Jellyfin and OStrm image digests and verifies OpenList release archives by SHA-256. This repository contains only the integration wrapper; the included applications retain their upstream licenses:

- [Jellyfin](https://github.com/jellyfin/jellyfin) — GPL-2.0
- [OpenList](https://github.com/OpenListTeam/OpenList) — AGPL-3.0
- [OStrm](https://github.com/hienao/ostrm) — GPL-3.0
- [Caddy](https://github.com/caddyserver/caddy) — Apache-2.0
