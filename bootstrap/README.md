# Zenlab host bootstrap

Download and verify the host bootstrap script from the public repository:

```bash
curl -fsSLO https://raw.githubusercontent.com/zenlab-dev/public-assets/main/bootstrap/zenlab-host.sh
curl -fsSLO https://raw.githubusercontent.com/zenlab-dev/public-assets/main/bootstrap/zenlab-host.sh.sha256
sha256sum -c zenlab-host.sh.sha256
sudo bash zenlab-host.sh
```

The script prepares a host for `zenlab-infra` CD by creating the `zenlab-cd`
user, installing the shared CI public key, preparing `/opt/zenlab-infra` and
`/opt/zenlab-data`, and restricting password login for the deploy user.

The host must already have Docker and Tailscale configured. The `zenlab-cd`
user is added to the `docker` group if that group exists.
