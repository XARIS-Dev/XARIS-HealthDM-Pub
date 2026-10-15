# HealthDM

HealthDM production releases for Linux servers. Each release has an `amd64` (Intel/AMD) and
an `arm64` (ARM) package. The installer picks the right one for your server automatically.

## Requirements

- 64-bit Linux server (`amd64` or `arm64`)
- Docker Engine with Docker Compose v2
- `curl`, `openssl` and `gzip`
- About 4 GB of free disk space and access to `github.com`

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/XARIS-Dev/XARIS-HealthDM-Pub/main/install.sh | bash -s -- --bind 0.0.0.0
```

When it finishes, the installer prints the address to open (`http://SERVER_ADDRESS:8800`)
and a one-time setup token. Open the address, enter the token and create the administrator
account.

HealthDM is installed in `/opt/healthdm`. Leave out `--bind 0.0.0.0` to make HealthDM
reachable from the server itself only, for example behind a reverse proxy.

## Upgrade

Run the same command again. The installer finds the existing installation, takes a verified
backup, then upgrades it in place. Your data and settings are kept.

## Stop and start

Run these from the installation directory. Your data is kept.

```bash
cd /opt/healthdm
docker compose stop      # stop HealthDM
docker compose start     # start it again
docker compose ps        # check status
```

A stopped HealthDM stays stopped after a server reboot until you start it again.

To also remove the containers, use `docker compose down` (your data is still kept), then
`docker compose up -d` to bring HealthDM back. Do not add `-v`: `docker compose down -v`
deletes the database and all HealthDM data.

If Docker needs administrator rights on your server, put `sudo` before each command.

## Options

Add options after `bash -s --`:

| Option | Description |
| --- | --- |
| `--version v2.0.0` | Install a specific release instead of the latest |
| `--bind 0.0.0.0` | Allow access from other machines (default: this server only) |
| `--port 8800` | HTTP port (default: 8800) |
| `--dir /opt/healthdm` | Install directory |
| `--backup-dir /path` | Where the upgrade backup is saved |

## Offline install

Download the `.tar.gz` for your server and the `.sha256` file from
[Releases](https://github.com/XARIS-Dev/XARIS-HealthDM-Pub/releases), then:

```bash
sha256sum -c --ignore-missing healthdm-v2.0.0-linux-checksums.sha256
tar -xzf healthdm-v2.0.0-linux-amd64.tar.gz
./healthdm-v2.0.0-linux-amd64/install.sh --bind 0.0.0.0
```

On ARM servers, use the `linux-arm64` file.

## Important

- Keep a copy of `/opt/healthdm/.env` somewhere safe. Stored credentials cannot be recovered
  without it.
- Never run `docker compose down -v`. It deletes all HealthDM data. To stop HealthDM, see
  [Stop and start](#stop-and-start).
- If HealthDM is reachable from other machines, restrict port 8800 with a firewall and put
  HTTPS in front of it.
