#! /usr/bin/python3
import sys

import apt

def auto_install(dependencies):
    for package in dependencies:
        # Pick the first version that apt returns for installation
        target = package.target_versions[0].package
        target.mark_install(from_user=False)

recommends = False
suggests = False
if sys.argv[1] == "recommends":
    recommends = True
elif sys.argv[1] == "suggests":
    suggests = True
elif sys.argv[1] == "both":
    recommends = True
    suggests = True
else:
    print(f"Usage: {sys.argv[0]} [recommends|suggests|both] package1 package2 ...")
    sys.exit(1)

# Disable apt's automatic handling depending on what is specified
if recommends:
    apt.apt_pkg.config.set("APT::Install-Recommends", "false")
if suggests:
    apt.apt_pkg.config.set("APT::Install-Suggests", "false")

cache = apt.Cache()

for name in sys.argv[2:]:
    package = cache[name]
    package.mark_install()
    candidate = package.candidate

    if recommends:
        auto_install(candidate.recommends)
    if suggests:
        auto_install(candidate.suggests)

changes = cache.get_changes()
if not changes:
    print("No changes to be made.")
    sys.exit(0)
sorted_changes = sorted(changes, key=lambda x: x.name)
print("The following packages will be installed:")
for change in sorted_changes:
    statuses = [change.candidate.version]
    if change.installed:
        statuses.append("upgraded")
    if change.is_auto_installed:
        statuses.append("auto")
    print(f"\t{change.name} ({', '.join(statuses)})")
print(f"{len(sorted_changes)} packages will be installed, upgraded, or removed.")
try:
    input("Apply changes? (Press Enter to continue or Ctrl+C to cancel)")
    cache.commit()
except KeyboardInterrupt:
    print("\nChanges cancelled.")
    sys.exit(1)
