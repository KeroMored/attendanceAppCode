#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
PUBSPEC = os.path.join(ROOT, 'pubspec.yaml')
BACKUP = PUBSPEC + '.bak'
IOS_SYMLINKS = os.path.join(ROOT, 'ios', '.symlinks', 'plugins')

def list_plugins():
    if not os.path.isdir(IOS_SYMLINKS):
        print('No ios/.symlinks/plugins directory found')
        return []
    return sorted([d for d in os.listdir(IOS_SYMLINKS) if os.path.isdir(os.path.join(IOS_SYMLINKS, d))])

def backup_pubspec():
    shutil.copyfile(PUBSPEC, BACKUP)

def restore_pubspec():
    if os.path.exists(BACKUP):
        shutil.move(BACKUP, PUBSPEC)

def remove_plugins_from_pubspec(remove_list):
    # naive line-based removal: remove lines that start with plugin name under dependencies
    with open(BACKUP, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    out = []
    in_deps = False
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.lstrip()
        if stripped.startswith('dependencies:'):
            in_deps = True
            out.append(line)
            i += 1
            continue
        if in_deps:
            # end of dependencies if next top-level section (dev_dependencies or flutter:) or line with no indent
            if line.startswith('dev_dependencies:') or line.startswith('flutter:'):
                in_deps = False
                out.append(line)
                i += 1
                continue
            # check if this line defines a dependency to remove
            matched = False
            for plugin in remove_list:
                if stripped.startswith(plugin + ':'):
                    matched = True
                    # skip this line
                    i += 1
                    break
            if matched:
                # skip
                continue
            else:
                out.append(line)
                i += 1
                continue
        else:
            out.append(line)
            i += 1
    with open(PUBSPEC, 'w', encoding='utf-8') as f:
        f.writelines(out)

def run(cmd, cwd=None, capture=False):
    print('RUN:', ' '.join(cmd))
    proc = subprocess.run(cmd, cwd=cwd, stdout=subprocess.PIPE if capture else None, stderr=subprocess.STDOUT if capture else None, text=True)
    if capture:
        return proc.returncode, proc.stdout
    return proc.returncode


def try_install():
    # run flutter pub get then pod install
    rc = run(['flutter', 'pub', 'get'], cwd=ROOT)
    if rc != 0:
        print('flutter pub get failed')
        return False, 'flutter pub get failed'
    # run pod install
    ios_dir = os.path.join(ROOT, 'ios')
    rc, out = run(['pod', 'install', '--repo-update'], cwd=ios_dir, capture=True)
    success = (rc == 0)
    return success, out


def bisect(plugins):
    candidates = plugins[:]
    round = 1
    while len(candidates) > 1:
        print('\nBISect round', round, 'candidates:', candidates)
        mid = len(candidates) // 2
        first_half = candidates[:mid]
        second_half = candidates[mid:]
        print('Testing removing first half (len=%d): %s' % (len(first_half), first_half))
        # backup original pubspec
        restore_pubspec()
        backup_pubspec()
        remove_plugins_from_pubspec(first_half)
        success, out = try_install()
        if success:
            print('pod install SUCCEEDED after removing first half -> problematic plugin is in first half')
            candidates = first_half
        else:
            print('pod install FAILED after removing first half -> problematic plugin is in second half')
            candidates = second_half
        round += 1
    return candidates[0] if candidates else None


def main():
    plugins = list_plugins()
    if not plugins:
        print('No plugins found to bisect.')
        return 1
    print('Found plugins to test:', plugins)
    # backup pubspec
    if not os.path.exists(BACKUP):
        backup_pubspec()
    try:
        culprit = bisect(plugins)
        print('\nCulprit plugin (likely):', culprit)
        print('Restoring original pubspec...')
        restore_pubspec()
    except Exception as e:
        print('Exception during bisect:', e)
        restore_pubspec()
        return 1
    return 0

if __name__ == '__main__':
    sys.exit(main())
