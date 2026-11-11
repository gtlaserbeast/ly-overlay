# ly-overlay

Gentoo overlay for [Ly](https://codeberg.org/fairyglade/ly) 1.5.0, a TUI
display manager. `::guru` stops at 1.4.1, and 1.5.0 needs Zig 0.17, which
`::gentoo` doesn't carry yet, so this overlay ships both.

## Install

```sh
eselect repository add ly-overlay git https://github.com/gtlaserbeast/ly-overlay.git
emaint sync -r ly-overlay
emerge --ask x11-misc/ly
```

`x11-misc/ly` is keyworded `~amd64`, and it builds with `dev-lang/zig-bin:0.17`
from `::gentoo`, which may also be `~amd64`. On a stable system accept both with

```sh
printf '%s\n' 'x11-misc/ly ~amd64' 'dev-lang/zig-bin ~amd64' \
    >> /etc/portage/package.accept_keywords/ly
```

## Packages

| Package | Description |
| --- | --- |
| `x11-misc/ly` | TUI display manager |

This overlay used to carry `dev-lang/zig-bin:0.17` as well; it was dropped once
`::gentoo` got `zig-bin-0.17.1`.

## Upgrading from 1.4.x

**OpenRC: fix the power keys.** 1.5.0 ignores `shutdown_cmd` and `restart_cmd`.
The shutdown and restart keys sync and call `reboot(2)` directly, so OpenRC
doesn't stop services or unmount filesystems. To go through `/sbin/shutdown`,
replace those keys with custom bindings in `/etc/ly/config.ini`:

```ini
shutdown_key = null
restart_key = null
corner_top_left = britup,britdown,password battery binds

[cmd:F1]
name = Shutdown
cmd = /sbin/shutdown -h now

[cmd:F2]
name = Restart
cmd = /sbin/shutdown -r now
```

`[cmd:*]` sections have to come after every plain option in the file. The
top-level options above, including `corner_top_left`, go before the first
section. Without `binds` in a corner the keys still work but aren't shown.

**`/etc/ly/setup.sh` changes.** Ebuilds from `::guru` left `$CONFIG_DIRECTORY`
unsubstituted in this file, so sessions never sourced `/etc/profile`. This
ebuild substitutes it, so sessions pick up `/etc/profile` once you merge the
new file with `dispatch-conf`.

Old options are migrated at startup, so an unmerged 1.4 `config.ini` still
loads. `ly --validate-config /etc/ly/config.ini` checks the file without
touching the tty; it catches bad values, not misspelled option names.

## Ebuild notes

`ly-1.5.0.ebuild` is a plain `zig.eclass` ebuild. Earlier revisions worked
around missing Zig 0.17 support in the eclass; those workarounds were removed
once `::gentoo` gained it, so sync `::gentoo` before building.

Bugs in the ebuilds go to this repo's issues; bugs in Ly itself go to
[Ly's issues](https://codeberg.org/fairyglade/ly/issues).

The ebuilds are distributed under the GNU General Public License v2, as their
headers say.
