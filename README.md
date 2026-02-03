# naver-cloud-cli-setup
Custom Github actions to setup Naver Cloud Platform client

# Setup NCLOUD CLI (GitHub Action)

Install the **NAVER Cloud Platform (NCP / NCLOUD) CLI** on a GitHub Actions runner and configure credentials non-interactively for CI/CD workflows.

This action:
- Downloads and installs NCLOUD CLI on the runner (Ubuntu/Linux runners)
- Adds `ncloud` to `PATH`
- Writes `~/.ncloud/configure` from GitHub Secrets (no interactive prompts)
- Optionally exports `NCLOUD_ACCESS_KEY`, `NCLOUD_SECRET_KEY`, `NCLOUD_API_GW`

> Docs reference:
> - Downloading/updates: https://cli.ncloud-docs.com/docs/en/guide-clichange  
> - Basic CLI usage/config: https://cli.ncloud-docs.com/docs/en/guide-userguide  

---

## Why this action?

Many private-network deployments (DMZ → private WAS) require CI pipelines that can:
1) authenticate to NCP APIs
2) issue CLI commands (infra, networking, registry workflows, etc.)
3) remain reproducible and secure across multiple repositories

This action centralizes those steps so **any repository** can reuse the same NCP setup reliably.

---

## Supported runners

✅ `ubuntu-latest` (Linux)

> Other OS support (Windows/macOS) is not included by default in this repo.  
> If you need it, add platform-specific installers and conditionals.

---

## Quick start

### 1) Add repository secrets (consumer repo)

In your consuming repository:
- `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

Add:
- `NCLOUD_ACCESS_KEY_ID`
- `NCLOUD_SECRET_ACCESS_KEY`

### 2) Use the action

```yaml
- name: Setup NCLOUD CLI
  uses: your-org/setup-ncloud-cli@v1
  with:
    access-key-id: ${{ secrets.NCLOUD_ACCESS_KEY_ID }}
    secret-access-key: ${{ secrets.NCLOUD_SECRET_ACCESS_KEY }}
    api-url: https://ncloud.apigw.ntruss.com
