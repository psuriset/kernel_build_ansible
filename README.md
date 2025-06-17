# Linux Kernel Build Ansible Playbook

This Ansible playbook automates the process of building the Linux kernel from source on Fedora/RHEL-based systems.

## Prerequisites

- Ansible 2.9 or higher
- Target system running Fedora or RHEL-based Linux distribution
- Sufficient disk space (at least 20GB recommended)
- Root or sudo privileges

## Configuration

The playbook uses variables defined in `vars/kernel_vars.yml`. You can modify these variables to customize the build:

- `kernel_version`: The version of the Linux kernel to build
- `kernel_config`: The configuration method to use (defconfig, oldconfig, or menuconfig)
- `num_cores`: Number of CPU cores to use for compilation

## Usage

1. Create an inventory file with your target hosts:

```ini
[build_hosts]
your_host ansible_host=your_host_ip
```

2. Run the playbook:

```bash
ansible-playbook -i inventory build_kernel.yml
```

## What the Playbook Does

1. Installs required build dependencies using dnf
2. Downloads the kernel source code
3. Extracts and prepares the source
4. Generates kernel configuration
5. Builds the kernel and modules
6. Installs the kernel and updates GRUB2
7. Creates initramfs using dracut

## Fedora/RHEL Specific Notes

- Uses dnf package manager instead of apt
- Uses grub2-mkconfig instead of update-grub
- Creates initramfs using dracut
- Installs Fedora/RHEL-specific build dependencies
- Uses the correct paths for GRUB2 configuration

## Notes

- The build process can take several hours depending on your system
- Make sure you have enough disk space
- The playbook will automatically use all available CPU cores for compilation
- After installation, you'll need to reboot to use the new kernel
- SELinux might need to be temporarily set to permissive mode during the build

## Troubleshooting

If you encounter any issues:

1. Check the system logs for errors
2. Ensure all required packages are installed
3. Verify you have sufficient disk space
4. Check that you have the correct permissions
5. If SELinux is causing issues, try:
   ```bash
   setenforce 0  # Temporarily disable SELinux
   ```
   Remember to re-enable it after the build:
   ```bash
   setenforce 1
   ```

## License

This project is licensed under the MIT License. 