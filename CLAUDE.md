# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ansible automation for building and installing Linux kernels from source, with specialized support for reproducing syzkaller-reported kernel bugs. Targets Fedora/RHEL-based systems.

## Common Commands

### Build Kernels

```bash
# Build stable kernel from kernel.org (uses vars/kernel_vars.yml)
ansible-playbook -i inventory.ini build_kernel.yml

# Build latest kernel from git (uses vars/kernel_git_vars.yml)
ansible-playbook -i inventory.ini build_kernel_from_bug.yml

# Build with specific bug config (override variables)
ansible-playbook -i inventory.ini build_kernel_from_bug.yml \
  -e "bug_url=https://syzkaller.appspot.com/bug?extid=XXXXX" \
  -e "install_kernel=false"

# Quick build without installation using shell script
./build_with_bug_config.sh
```

### Testing Playbooks

```bash
# Syntax check
ansible-playbook --syntax-check build_kernel.yml

# Dry run (check mode)
ansible-playbook -i inventory.ini build_kernel.yml --check

# Run with verbose output
ansible-playbook -i inventory.ini build_kernel_from_bug.yml -v
```

## Architecture

### Playbook Structure

**Two main workflows:**

1. **Stable kernel builds** (`build_kernel.yml`)
   - Downloads kernel tarball from kernel.org
   - Extracts to `/usr/src/linux-VERSION-build/`
   - Uses `defconfig` or copies running kernel config (`oldconfig`)
   - Always installs the kernel

2. **Git-based builds** (`build_kernel_from_bug.yml`)
   - Clones/updates linux.git to `/usr/src/linux-git/`
   - Optionally fetches kernel config from syzkaller bug reports
   - Supports shallow clones for faster downloads
   - Installation is optional (controlled by `install_kernel` variable)

### Task Files

- `tasks/build_kernel.yml` - Stable kernel build pipeline (download → configure → build → install)
- `tasks/fetch_kernel_git.yml` - Git repository management (clone or update)
- `tasks/build_kernel_from_git.yml` - Git kernel build pipeline (configure → build → optional install)
- `tasks/fetch_bug_config.yml` - Downloads kernel config from syzkaller bug URLs

### Variable Files

- `vars/kernel_vars.yml` - Stable kernel configuration (version, packages, paths)
- `vars/kernel_git_vars.yml` - Git kernel configuration (repo URL, branch, bug URLs, install option)

Both var files define `kernel_build_dir` - stable builds use versioned paths, git builds use `kernel_git_dir`.

### Syzkaller Bug Config Workflow

The `fetch_bug_config.yml` task attempts to convert a syzkaller bug URL to a kernel config URL:

```
Bug URL: https://syzkaller.appspot.com/bug?extid=XXXXX
  ↓ (regex extraction - CURRENTLY BROKEN)
Config URL: https://syzkaller.appspot.com/text?tag=KernelConfig&x=HASH
```

**Important:** The current regex-based URL conversion is fundamentally flawed because the config hash cannot be derived from the bug extid. Users must provide the direct `kernel_bug_config_url` or the bug page needs to be scraped.

## Key Implementation Details

### Build Idempotency

- Stable builds: Uses `creates` parameter on unarchive and build tasks to skip if already done
- Git builds: Uses `.build-complete` marker file to skip rebuild if present
- Both: `make mrproper` or `make clean` run unconditionally before builds (not idempotent)

### GRUB Configuration

Auto-detects UEFI vs BIOS boot:
- UEFI: `/boot/efi/EFI/redhat/grub.cfg`
- BIOS: `/boot/grub2/grub.cfg` (default from `grub_cfg_path`)

### Parallel Builds

Uses `num_cores: "{{ ansible_processor_vcpus | default(2) }}"` to auto-detect CPU count for `make -j`.

### Root Permissions

Most tasks require `become: true` because they operate in `/usr/src/` and `/boot/`. Git builds run as root even for non-install builds.

## Variable Precedence

Variables can be overridden via:
1. Playbook extra vars (`-e "var=value"`) - highest precedence
2. `vars/` files loaded by playbook
3. Ansible defaults - lowest precedence

Common overrides: `install_kernel`, `bug_url`, `kernel_bug_config_url`, `clean_before_build`, `reboot_after_build`

## Safety Mechanisms

- `install_kernel: false` by default in git builds (prevents accidental system changes)
- `reboot_after_build: false` by default (manual reboot required)
- Build artifacts isolated in `/usr/src/` directories
- Config validation checks (file size > 0) before build proceeds

## System Requirements

- Fedora/RHEL-based distribution (uses `dnf` and RedHat-specific paths)
- 20+ GB free disk space (for full git clone)
- Root/sudo access
- Required packages installed via `required_packages` list in `kernel_vars.yml`
