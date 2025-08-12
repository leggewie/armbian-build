#! /usr/bin/python3
import sys, os, apt, subprocess

def auto_install(dependencies):
    for package in dependencies:
        # Pick the first version that apt returns for installation
        target = package.target_versions[0].package
        target.mark_install(from_user=False)

recommends = False
suggests = False

try:
    if os.geteuid() != 0:
        raise PermissionError("The script must be run as root!")
    # Check if at least two arguments are provided
    if len(sys.argv) < 3:
        raise IndexError("Insufficient arguments")
    if sys.argv[1] in "recommends":
        recommends = True
    elif sys.argv[1] == "suggests":
        suggests = True
    elif sys.argv[1] == "both":
        recommends = True
        suggests = True
    else:
        raise ValueError("Please specify what additional packages should be installed!")
except PermissionError as e:
    print(f"Error: {e}")
    sys.exit(1)
except (IndexError, ValueError) as e:
    print(f"Usage: {sys.argv[0]} [recommends|suggests|both] package1 package2 ...\n\n{e}")
    sys.exit(2)
except:
    print(f"Unknown error")
    sys.exit(3)

# disable automatic installation of Suggests and Recommends
apt.apt_pkg.config.set("APT::Install-Recommends", "false")
apt.apt_pkg.config.set("APT::Install-Suggests", "false")

cache = apt.Cache()

for name in sys.argv[2:]:
    # XXX handle error if package is not actually a package, no installation candidate
    try:
        package = cache[name]
        package.mark_install()
        candidate = package.candidate
        if recommends:
            auto_install(candidate.recommends)
        if suggests:
            auto_install(candidate.suggests)
    except:
        print(name + " has no installation candidate.")
        sys.exit(4)

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
    answer = input("Apply changes? (Press Enter to continue or Ctrl+C to cancel) ")
    if answer.lower() in ["", "y", "yes"]:
        cache.commit()
    else:
        print("\nOK, changes cancelled.")
        sys.exit(1)
except KeyboardInterrupt:
    print("\nChanges cancelled.")
    sys.exit(1)
# the following does not work as expected
except LockFailedException as e:
    print("\nAnother process is managing the package cache at the moment.\n\n{e}")
