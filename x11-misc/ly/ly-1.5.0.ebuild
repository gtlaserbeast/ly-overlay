# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Ly - a TUI display manager"
HOMEPAGE="https://codeberg.org/fairyglade/ly"

# zlua also declares lua51..lua55 and luau, but they are lazy and only
# fetched for the language selected in build.zig, which is LuaJIT.
declare -g -r -A ZBS_DEPENDENCIES=(
	[aro-0.0.0-JSD1QtuBNwCASyBtNF3pqTl_W3oAJQGEVyFAtrBSE_Pa.tar.gz]='https://codeberg.org/ziglang/arocc/archive/d0c8c4d9c55daa7ef6e40cf0f630a5b5e900989b.tar.gz'
	[clap-0.12.0-oBajB4XpAQCF1WRKnD5KOKPsnwwT_NNdAJ7Ww3irYJac.tar.gz]='https://github.com/Hejsil/zig-clap/archive/05faf3905e8548f5cc269a8836e154065e70128d.tar.gz'
	[ini-0.1.0-YCQ9YnsrAAAxl1kQHi95ths2vSkdPIJxzUg6e2Oo83w_.tar.gz]='https://github.com/ziglibs/ini/archive/10cfba648f709588ab2f8785f56641024c510df9.tar.gz'
	[translate_c-0.0.0-Q_BUWoROBwAyokT5SJSw4YIrwdLd1w53i-pEYwBDqXZt.tar.gz]='https://codeberg.org/ziglang/translate-c/archive/38d8339d9050eafe5dcf85b4fc9368576ca967e1.tar.gz'
	[zigini-0.6.0-BSkB7UtYAAB6b6HEm3Pjj5WIy-uiuBYsNTNCUENVwL1t.tar.gz]='https://github.com/AshAmetrine/zigini/archive/085badbf90e25016f4609b5bde334689cdb41c5c.tar.gz'
	[zlua-0.1.0-hGRpC9eYBQDYOfd1aKlHG8hy8eTgKiaAdIyQEQgLREpI.tar.gz]='https://github.com/AnErrupTion/ziglua/archive/5ff4bcc7b56661125dd93ad81addd473cebbcd14.tar.gz'
	[N-V-__8AAODpQgCVrpfzE2ze9FA_rOuByh3WKyIyk5iS_o9a.tar.gz]='https://github.com/LuaJIT/LuaJIT/archive/18b087cd2cd4ddc4a79782bf155383a689d5093d.tar.gz'
	[N-V-__8AAOEWBQDt5tNdIzIFY6n8DdZsCP-6MyLoNS20wgpA.tar.gz]='https://github.com/AnErrupTion/termbox2/archive/496730697c662893eec43192f48ff616c2539da6.tar.gz'
)

ZIG_SLOT="0.17"

inherit pam systemd zig

SRC_URI="
	https://codeberg.org/fairyglade/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz
	${ZBS_DEPENDENCIES_SRC_URI}
"

S="${WORKDIR}/${PN}"

# ly: WTFPL-2; statically linked LuaJIT, clap, ini, zigini, termbox2: MIT
LICENSE="WTFPL-2 MIT"
SLOT="0"
KEYWORDS="~amd64"

IUSE="X"

DEPEND="
	sys-libs/pam
	X? (
		x11-libs/libxcb
	)
"
RDEPEND="
	${DEPEND}
	app-misc/brightnessctl
	X? (
		x11-base/xorg-server
		x11-apps/xauth
		x11-apps/xrdb
		x11-apps/xmessage
	)
"

# https://github.com/ziglang/zig/issues/3382
QA_FLAGS_IGNORED="usr/bin/ly"

src_prepare() {
	zig_src_prepare

	# Same substitutions as upstream's install.zig
	sed -e "s|\$PREFIX_DIRECTORY|/usr|g" \
		-e "s|\$EXECUTABLE_NAME|ly|g" \
		-e "s|\$DEFAULT_TTY|2|g" \
		-e "s|\$CONFIG_DIRECTORY|/etc|g" \
		-i res/${PN}@.service \
		-i res/${PN}-kmsconvt@.service \
		-i res/${PN}-openrc \
		-i res/config.ini \
		-i res/setup.sh \
		-i res/custom-sessions/README || die
}

src_configure() {
	local my_zbs_args=(
		-Denable_x11_support=$(usex X true false)
	)

	zig_src_configure
}

src_install() {
	zig_src_install

	dodoc readme.md

	newinitd res/${PN}-openrc ${PN}

	systemd_dounit res/${PN}@.service
	systemd_dounit res/${PN}-kmsconvt@.service

	insinto /etc/${PN}
	doins res/config.ini res/example.dur res/example.lua
	newins res/config.ini config.ini.example

	exeinto /etc/${PN}
	doexe res/setup.sh res/startup.sh

	insinto /etc/${PN}/custom-sessions
	doins res/custom-sessions/README

	insinto /etc/${PN}/lang
	doins res/lang/*.ini

	newpamd res/pam.d/ly-linux ly
	newpamd res/pam.d/ly-linux-autologin ly-autologin
}

pkg_postinst() {
	ewarn "Since 1.5.0, shutdown_cmd and restart_cmd are ignored: the shutdown and"
	ewarn "restart keys sync and call reboot(2) directly, so on OpenRC services are"
	ewarn "not stopped and filesystems are not unmounted.  See the overlay's README"
	ewarn "for custom key bindings that go through /sbin/shutdown instead."
}
