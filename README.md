# Linux Kernel Build Ansible Playbook (Improved)

This playbook builds a Linux kernel on RHEL/Fedora with fixes for:
- Non-interactive config (uses olddefconfig)
- Correct kernel release detection
- GRUB path auto-detection (BIOS/UEFI)
- Proper permissions using become
- Idempotent build using stamp file

## Key Improvements

- Uses running kernel config when `oldconfig` is selected
- Avoids interactive prompts
- Uses actual built kernel version instead of static version
- Handles UEFI vs BIOS automatically

## Usage

```bash
ansible-playbook -i inventory build_kernel.yml
```

## Optional

```yaml
reboot_after_build: true
```
