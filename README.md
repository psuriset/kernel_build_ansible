# Kernel Build Ansible

Ansible playbooks for building and installing Linux kernel from source.

## Features

- Build kernel from kernel.org tarball (stable releases)
- Build kernel from git repository (latest upstream)
- Download and use kernel configs from syzkaller bug reports
- Support for custom kernel configurations
- Automated installation and GRUB configuration

## Prerequisites

- Fedora/RHEL-based system
- Ansible installed
- Sufficient disk space (20+ GB recommended for git repository)
- Root/sudo access

## Playbooks

### 1. Build Kernel from Stable Release

Build a specific kernel version from kernel.org:

```bash
ansible-playbook build_kernel.yml
```

Configuration in `vars/kernel_vars.yml`:
- `kernel_version`: Kernel version to build (e.g., "6.12.93")
- `kernel_config`: Configuration method ("defconfig" or "oldconfig")

### 2. Build Kernel from Git with Bug Config

Build the latest kernel from git repository, optionally using a config from a syzkaller bug report:

```bash
ansible-playbook build_kernel_from_bug.yml
```

Configuration in `vars/kernel_git_vars.yml`:

To use a kernel config from a syzkaller bug report:

1. Visit the bug URL (e.g., `https://syzkaller.appspot.com/bug?extid=f2b5401166003c7d09c1`)
2. Click the "Kernel config" link on the bug page
3. Copy the config URL from your browser
4. Set it in `vars/kernel_git_vars.yml`:

```yaml
kernel_bug_config_url: "https://syzkaller.appspot.com/text?tag=KernelConfig&x=3e19fa1907a3dfda"
```

## Configuration Options

### Common Variables (`vars/common.yml`)

These variables apply to all build types:

```yaml
num_cores: 4                    # Number of CPU cores for parallel build
reboot_after_build: false       # Auto-reboot after installation
grub_cfg_path: "/boot/grub2/grub.cfg"
```

### Stable Kernel Variables (`vars/kernel_vars.yml`)

```yaml
kernel_version: "6.12.93"       # Kernel version to build
kernel_config: "defconfig"      # Configuration method
clean_before_build: false       # Run 'make clean' before build
```

### Git-specific Variables (`vars/kernel_git_vars.yml`)

```yaml
kernel_git_repo: "https://github.com/torvalds/linux.git"
kernel_git_dir: "/usr/src/linux-git"
kernel_git_branch: "master"     # Branch, tag, or commit
kernel_git_update: true         # Pull latest changes
clean_before_build: true        # Run 'make mrproper' before build
install_kernel: false           # Install after building
```

## Usage Examples

### Example 1: Build latest kernel with syzkaller bug config

1. Visit the bug page and get the kernel config URL:
   - Go to: `https://syzkaller.appspot.com/bug?extid=f2b5401166003c7d09c1`
   - Click "Kernel config" link
   - Copy the URL

2. Edit `vars/kernel_git_vars.yml`:
```yaml
kernel_bug_config_url: "https://syzkaller.appspot.com/text?tag=KernelConfig&x=3e19fa1907a3dfda"
install_kernel: false  # Just build, don't install
```

3. Run the playbook:
```bash
ansible-playbook build_kernel_from_bug.yml
```

### Example 2: Build and install latest kernel

1. Edit `vars/kernel_git_vars.yml`:
```yaml
install_kernel: true
reboot_after_build: false
```

2. Run the playbook:
```bash
ansible-playbook build_kernel_from_bug.yml
```

3. Manually reboot when ready:
```bash
sudo reboot
```

### Example 3: Build specific kernel version

1. Edit `vars/kernel_vars.yml`:
```yaml
kernel_version: "6.12.93"
kernel_config: "defconfig"
```

2. Run the playbook:
```bash
ansible-playbook build_kernel.yml
```

### Example 4: Quick build without installation

1. Edit `vars/kernel_git_vars.yml`:
```yaml
kernel_git_depth: 1          # Shallow clone for speed
clean_before_build: true
install_kernel: false
```

2. Run the playbook:
```bash
ansible-playbook build_kernel_from_bug.yml
```

## Workflow for Reproducing Kernel Bugs

1. Find a syzkaller bug report (e.g., https://syzkaller.appspot.com/bug?extid=f2b5401166003c7d09c1)

2. Open the bug page in your browser and extract the kernel config URL:
   - Click the "Kernel config" link on the bug page
   - Copy the URL (e.g., `https://syzkaller.appspot.com/text?tag=KernelConfig&x=3e19fa1907a3dfda`)

3. Add the config URL to `vars/kernel_git_vars.yml`:
```yaml
kernel_bug_config_url: "https://syzkaller.appspot.com/text?tag=KernelConfig&x=3e19fa1907a3dfda"
```

4. Build the kernel:
```bash
ansible-playbook build_kernel_from_bug.yml
```

5. The playbook will:
   - Clone/update the Linux git repository
   - Download the kernel config from the URL
   - Build the kernel with that config
   - Optionally install the kernel

## Directory Structure

```
.
├── build_kernel.yml                 # Stable kernel build playbook
├── build_kernel_from_bug.yml        # Git-based build with bug config
├── tasks/
│   ├── build_kernel.yml             # Build tasks for stable kernel
│   ├── build_kernel_from_git.yml    # Build tasks for git kernel
│   ├── fetch_kernel_git.yml         # Git clone/update tasks
│   └── fetch_bug_config.yml         # Download bug config tasks
└── vars/
    ├── kernel_vars.yml              # Stable kernel variables
    └── kernel_git_vars.yml          # Git kernel variables
```

## Troubleshooting

### Build fails due to missing dependencies

Check that all required packages are listed in `vars/kernel_vars.yml` under `required_packages`.

### Git clone is very slow

Use shallow clone:
```yaml
kernel_git_depth: 1
```

### Config download fails

- Verify the bug URL is correct
- Check network connectivity
- Try using the direct config URL instead

### Out of disk space

The git repository can be large (several GB). Ensure you have at least 20GB free space.

## Safety Features

- `install_kernel: false` by default - prevents accidental installation
- `reboot_after_build: false` by default - manual reboot required
- Build artifacts isolated in `/usr/src/`
- Config verification before build

## License

MIT

## Contributing

Pull requests welcome! Please test changes on a VM before submitting.
