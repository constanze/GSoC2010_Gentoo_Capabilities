# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/iputils/iputils-20071127.ebuild,v 1.10 2008/04/20 20:55:59 vapier Exp $

inherit flag-o-matic eutils toolchain-funcs

DESCRIPTION="Network monitoring tools including ping and ping6"
HOMEPAGE="http://www.linux-foundation.org/en/Net:Iputils"
SRC_URI="http://www.skbuff.net/iputils/iputils-s${PV}.tar.bz2
	mirror://gentoo/iputils-s${PV}-manpages.tar.bz2"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE="static ipv6 doc"

DEPEND="virtual/os-headers
	doc? (
		app-text/openjade
		dev-perl/SGMLSpm
		app-text/docbook-sgml-dtd
		app-text/docbook-sgml-utils
	)"
RDEPEND="!net-misc/rarpd"

S=${WORKDIR}/${PN}-s${PV}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-gcc34.patch
	epatch "${FILESDIR}"/021109-uclibc-no-ether_ntohost.patch
	epatch "${FILESDIR}"/${PN}-20070202-makefile.patch
	epatch "${FILESDIR}"/${P}-kernel-ifaddr.patch
	epatch "${FILESDIR}"/${PN}-20060512-linux-headers.patch
	epatch "${FILESDIR}"/${PN}-20070202-no-open-max.patch #195861

	use static && append-ldflags -static
	use ipv6 || sed -i -e 's:IPV6_TARGETS=:#IPV6_TARGETS=:' Makefile
}

src_compile() {
	tc-export CC
	emake || die "make main failed"

	# We include the extra check for docbook2html
	# because when we emerge from a stage1/stage2,
	# it may not exist #23156
	if use doc && type -P docbook2html >/dev/null ; then
		emake -j1 html || die
	fi
}

src_install() {
	into /
	dobin ping || die "ping"
	use ipv6 && dobin ping6
	dosbin arping || die "arping"
	into /usr
	dosbin tracepath || die "tracepath"
	use ipv6 && dosbin trace{path,route}6
	dosbin clockdiff rarpd rdisc ipg tftpd || die "misc sbin"

	#fperms 4711 /bin/ping
	use ipv6 && fperms 4711 /bin/ping6 /usr/sbin/traceroute6

	dodoc INSTALL RELNOTES
	use ipv6 \
		&& dosym ping.8 /usr/share/man/man8/ping6.8 \
		|| rm -f doc/*6.8
	rm -f doc/setkey.8
	doman doc/*.8

	use doc && dohtml doc/*.html
}

pkg_postinst()
{
	fcaps cap_net_raw=ep /bin/ping || die "dosetcap failed with ping"
}

