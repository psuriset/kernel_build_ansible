#!/bin/bash
# Example: Build kernel with bug config from syzkaller

# Set the bug URL or config URL
BUG_URL="https://syzkaller.appspot.com/bug?extid=f2b5401166003c7d09c1"

# Run the playbook with extra variables
ansible-playbook -i inventory.ini build_kernel_from_bug.yml \
  -e "bug_url=${BUG_URL}" \
  -e "install_kernel=false" \
  -e "clean_before_build=true"

echo "Build complete! Check /usr/src/linux-git for the built kernel."
echo "To install: Set install_kernel=true in vars/kernel_git_vars.yml and re-run."
