# HealthDM

HealthDM production releases for Linux servers. Each release has an `amd64` (Intel/AMD) and
an `arm64` (ARM) package. Use the one that matches your server's CPU.

## System requirements

Sizing for one Linux server running the full HealthDM stack, with one scheduled health check
per tenant per week. One assessment takes about 5 to 7 minutes, mostly waiting on the Cortex
API, and adds about 20 MB to the database.

### Hardware

| Resource | 10 tenants (minimum / recommended) | 100 tenants (minimum / recommended) |
| --- | --- | --- |
| CPU | 2 vCPU / 4 vCPU | 4 vCPU / 8 vCPU |
| RAM | 8 GB / 12 GB | 12 GB / 16 GB |
| Disk (SSD) | 60 GB / 120 GB | 150 GB / 300 GB |
| Database growth | ~10 GB per year | ~100 GB per year |
| Network (outbound HTTPS to Cortex) | 10 Mbps / 50 Mbps | 50 Mbps / 100 Mbps |

Disk includes Docker images and upgrade headroom, log files (kept 14 days), backup space and
generated PDF reports. The database is the only part that grows over time, so size the disk
for at least one year of growth.

### Software

| Component | Requirement |
| --- | --- |
| Operating system | 64-bit Linux (`amd64` or `arm64`): Ubuntu 22.04 / 24.04 LTS, or RHEL 9 and derivatives |
| Docker Engine | 24.0 or newer |
| Docker Compose | v2.23 or newer |
| Tools | `curl`, `openssl` and `gzip` |
| Kernel | Unprivileged user namespaces enabled (used by the PDF sandbox). The installer checks this and adjusts the setting itself if they are not available. |
| Inbound port | 8800 (HTTP), or 443 through your own HTTPS reverse proxy |
| Outbound access | HTTPS (443) to `github.com` for install and upgrade, and to each Cortex tenant API |
| Time | NTP-synchronised clock (scheduling and sign-in sessions depend on it) |
| Browser (users) | Current Chrome, Edge, Firefox or Safari |

### Settings for 100 tenants

The defaults suit about 10 tenants. For about 100 tenants, edit `/opt/healthdm/.env`:

```bash
WORKER_CONCURRENCY=8      # tenants assessed at the same time (default 4)
WORKER_MEMORY_LIMIT=8g    # worker memory limit (default 6g)
```

Then apply the change with `cd /opt/healthdm && docker compose up -d`. With 8 workers,
100 tenants finish in roughly 70 minutes.

## Install

Run the command for your server's CPU. `uname -m` shows `x86_64` on Intel/AMD servers and
`aarch64` on ARM servers. Each command downloads the release, verifies its SHA-256 checksum,
then runs the installer.

**Intel/AMD (`amd64`):**

```bash
curl -fLO https://github.com/XARIS-Dev/XARIS-HealthDM-Pub/releases/download/v2.0.0/healthdm-v2.0.0-linux-amd64.tar.gz \
  && curl -fLO https://github.com/XARIS-Dev/XARIS-HealthDM-Pub/releases/download/v2.0.0/healthdm-v2.0.0-linux-checksums.sha256 \
  && sha256sum -c --ignore-missing healthdm-v2.0.0-linux-checksums.sha256 \
  && tar -xzf healthdm-v2.0.0-linux-amd64.tar.gz \
  && ./healthdm-v2.0.0-linux-amd64/install.sh --bind 0.0.0.0
```

**ARM (`arm64`):**

```bash
curl -fLO https://github.com/XARIS-Dev/XARIS-HealthDM-Pub/releases/download/v2.0.0/healthdm-v2.0.0-linux-arm64.tar.gz \
  && curl -fLO https://github.com/XARIS-Dev/XARIS-HealthDM-Pub/releases/download/v2.0.0/healthdm-v2.0.0-linux-checksums.sha256 \
  && sha256sum -c --ignore-missing healthdm-v2.0.0-linux-checksums.sha256 \
  && tar -xzf healthdm-v2.0.0-linux-arm64.tar.gz \
  && ./healthdm-v2.0.0-linux-arm64/install.sh --bind 0.0.0.0
```

The download is about 800 MB and is saved in the current directory.

When it finishes, the installer prints the address to open (`http://SERVER_ADDRESS:8800`)
and a one-time setup token. Open the address, enter the token and create the administrator
account.

HealthDM is installed in `/opt/healthdm`. Leave out `--bind 0.0.0.0` to make HealthDM
reachable from the server itself only, for example behind a reverse proxy.

## Upgrade

Run the install command for your server's CPU from the new release. The installer finds the
existing installation, takes a verified backup, then upgrades it in place. Your data and
settings are kept.

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

Add options after `install.sh` at the end of the install command:

| Option | Description |
| --- | --- |
| `--bind 0.0.0.0` | Allow access from other machines (default: this server only) |
| `--port 8800` | HTTP port (default: 8800) |
| `--dir /opt/healthdm` | Install directory |
| `--backup-dir /path` | Where the upgrade backup is saved |

## Offline install

For a server without internet access, download the `.tar.gz` for your server and the
`.sha256` file from [Releases](https://github.com/XARIS-Dev/XARIS-HealthDM-Pub/releases) on
another machine, copy both to the server, then:

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
