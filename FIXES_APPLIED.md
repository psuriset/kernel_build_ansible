# Fixes Applied

This document describes the fixes and restructuring applied to the kernel_build_ansible project.

## Files Modified

### Critical Fixes

#### 1. Fixed Broken Syzkaller Config URL Extraction
**File:** `tasks/fetch_bug_config.yml`

**Changes:**
- Removed broken regex-based URL extraction that attempted to derive config hash from bug extid
- Added clear error message directing users to manually extract the kernel config URL
- Added documentation explaining why automatic extraction is impossible

**Impact:** Users must now manually copy the kernel config URL from syzkaller bug pages instead of relying on broken automatic extraction.

**Migration:**
```yaml
# OLD (broken):
bug_url: "https://syzkaller.appspot.com/bug?extid=f2b5401166003c7d09c1"

# NEW (working):
# 1. Visit the bug URL
# 2. Click "Kernel config" link
# 3. Copy that URL:
kernel_bug_config_url: "https://syzkaller.appspot.com/text?tag=KernelConfig&x=3e19fa1907a3dfda"
```

#### 2. Added Missing Root Permissions to make clean
**File:** `tasks/build_kernel.yml`

**Changes:**
- Added `become: true` to the make clean task
- Made make clean conditional on `clean_before_build` variable (default: false)

**Impact:** Stable kernel builds now support optional cleaning and won't fail with permission errors.

### Variable Consolidation

#### 3. Created Common Variables File
**File:** `vars/common.yml` (NEW)

**Changes:**
- Extracted shared variables from `kernel_vars.yml` and `kernel_git_vars.yml`:
  - `num_cores`
  - `reboot_after_build`
  - `grub_cfg_path`
  - `required_packages`

**Impact:** Single source of truth for shared configuration, easier maintenance.

#### 4. Updated Playbooks to Load Common Variables
**Files:** `build_kernel.yml`, `build_kernel_from_bug.yml`

**Changes:**
- Added `vars/common.yml` to `vars_files` list (loaded first)
- Removed `vars/kernel_vars.yml` from git playbook (not needed)

**Migration:** No changes needed - common.yml is automatically loaded.

#### 5. Cleaned Up Variable Files
**Files:** `vars/kernel_vars.yml`, `vars/kernel_git_vars.yml`

**Changes:**
- Removed duplicate variables now in common.yml
- Added documentation comments referencing common.yml
- Added `clean_before_build` variable to kernel_vars.yml for consistency
- Improved documentation for `kernel_git_update` variable
- Removed `bug_url` support (broken feature)
- Made `kernel_bug_config_url` the only supported method

**Impact:** Clearer separation of concerns, reduced duplication.

## Files Added

1. **CLAUDE.md** - Comprehensive documentation for Claude Code
2. **CODE_REVIEW.md** - Detailed analysis of all issues found
3. **vars/common.yml** - Shared variables across all builds
4. **FIXES_APPLIED.md** - This file

## Remaining Issues (Not Fixed)

The following issues from CODE_REVIEW.md were documented but not fixed in this pass:

### Moderate Priority
- **Inconsistent kernel_build_dir naming:** The variable has different semantics in stable vs git builds. Consider renaming to `stable_build_dir` and `git_build_dir` in a future refactor.

### Low Priority
- **No build validation:** The build success is only verified by checking for marker files, not actual kernel artifacts.
- **No async error handling:** Long builds timeout after 2 hours but there's no cleanup on partial failure.
- **RedHat-only support:** The playbooks are hardcoded for Fedora/RHEL. Adding Debian/Ubuntu support would require additional work.
- **Hardcoded GRUB paths:** UEFI detection uses RedHat-specific paths.

## Testing Recommendations

After applying these fixes, test the following scenarios:

### Test 1: Stable Kernel Build
```bash
# Verify common.yml is loaded and build works
ansible-playbook -i inventory.ini build_kernel.yml --check

# Verify clean_before_build works
ansible-playbook -i inventory.ini build_kernel.yml -e "clean_before_build=true" --check
```

### Test 2: Git Kernel Build with Direct Config URL
```bash
# Edit vars/kernel_git_vars.yml:
# kernel_bug_config_url: "https://syzkaller.appspot.com/text?tag=KernelConfig&x=XXXXX"

ansible-playbook -i inventory.ini build_kernel_from_bug.yml --check
```

### Test 3: Git Kernel Build without Config
```bash
# Comment out kernel_bug_config_url in vars/kernel_git_vars.yml
ansible-playbook -i inventory.ini build_kernel_from_bug.yml --check
# Should use defconfig
```

### Test 4: Variable Override
```bash
# Verify extra vars still work
ansible-playbook -i inventory.ini build_kernel_from_bug.yml \
  -e "num_cores=8" \
  -e "install_kernel=false" \
  --check
```

## Backward Compatibility

### Breaking Changes

1. **bug_url is no longer supported** - Users relying on `bug_url` variable must switch to `kernel_bug_config_url`

   **Migration:**
   - Visit the syzkaller bug URL in a browser
   - Find and click the "Kernel config" link
   - Copy the direct config URL
   - Set `kernel_bug_config_url` to that URL

2. **make clean behavior changed** - In stable builds, make clean is now conditional (default: off)

   **Migration:**
   - To preserve old behavior: set `clean_before_build: true` in `kernel_vars.yml`
   - Recommended: leave as false for faster, idempotent builds

### Non-Breaking Changes

All other changes are backward compatible:
- Common variables are loaded automatically
- Extra vars (`-e`) override behavior unchanged
- All existing variable names still work
- Playbook interfaces unchanged

## Files You Can Remove (Optional)

None. All original files were updated in-place.

## Recommended Next Steps

1. **Test the fixes** using the test scenarios above
2. **Update README.md** to reflect the `kernel_bug_config_url` requirement
3. **Consider the restructuring recommendations** in CODE_REVIEW.md for a more maintainable layout
4. **Add build validation** to verify kernel artifacts exist after build
5. **Add Debian/Ubuntu support** if needed for broader compatibility
