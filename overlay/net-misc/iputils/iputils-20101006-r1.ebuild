# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/iputils/iputils-20101006.ebuild,v 1.1 2011/02/19 18:09:49 vapier Exp $

# For released versions, we precompile the man/html pages and store
# them in a tarball on our mirrors.  This avoids ugly issues while
# building stages, and when the jade/sgml packages are broken (which
# seems to be more common than would be nice).

EAPI="2"

inherit flag-o-matic eutils toolchain-funcs fcaps
if [[ ${PV} == "99999999" ]] ; then
	EGIT_REPO_URI="git://www.linux-ipv6.org/gitroot/iputils"
	inherit git
else
	SRC_URI="http://www.skbuff.net/iputils/iputils-s${PV}.tar.bz2
		mirror://gentoo/iputils-s${PV}-manpages.tar.bz2"
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~amd64-linux ~x86-linux"
fi

DESCRIPTION="Network monitoring tools including ping and ping6"
HOMEPAGE="http://www.linux-foundation.org/en/Net:Iputils"

LICENSE="BSD"
SLOT="0"
IUSE="doc filecaps idn ipv6 SECURITY_HAZARD ssl static"

# sysfsutils is needed for libsysfs which is used by arping only
RDEPEND="!net-misc/rarpd
	ssl? ( dev-libs/openssl )
	idn? ( net-dns/libidn )
	sys-fs/sysfsutils"
DEPEND="${RDEPEND}
	virtual/os-headers"
if [[ ${PV} == "99999999" ]] ; then
	DEPEND+="
		app-text/openjade
		dev-perl/SGMLSpm
		app-text/docbook-sgml-dtd
		app-text/docbook-sgml-utils
	"
fi

S=${WORKDIR}/${PN}-s${PV}

src_prepare() {
	epatch "${FILESDIR}"/021109-uclibc-no-ether_ntohost.patch
	epatch "${FILESDIR}"/${PN}-20100418-openssl.patch #335436
	epatch "${FILESDIR}"/${PN}-20100418-so_mark.patch #335347
	epatch "${FILESDIR}"/${PN}-20100418-makefile.patch
	epatch "${FILESDIR}"/${PN}-20100418-proper-libs.patch #332703
	epatch "${FILESDIR}"/${PN}-20100418-printf-size.patch
	epatch "${FILESDIR}"/${PN}-20100418-aliasing.patch
	epatch "${FILESDIR}"/${PN}-20071127-kernel-ifaddr.patch
	epatch "${FILESDIR}"/${PN}-20070202-idn.patch #218638
	use SECURITY_HAZARD && epatch "${FILESDIR}"/${PN}-20071127-nonroot-floodping.patch
	use static && append-ldflags -static
	use ssl && append-cppflags -DHAVE_OPENSSL
	use ipv6 || sed -i -e 's:IPV6_TARGETS=:#IPV6_TARGETS=:' Makefile
	export IDN=$(use idn && echo yes)
}

src_compile() {
	tc-export CC
	emake || die

	if [[ ${PV} == "99999999" ]] ; then
		emake -j1 html man || die
	fi
}

src_install() {
	into /
	dobin ping || die
	use ipv6 && dobin ping6
	dosbin arping || die
	into /usr
	dosbin tracepath || die
	use ipv6 && dosbin trace{path,route}6
	dosbin clockdiff rarpd rdisc ipg tftpd || die

	fcaps root:root 4711 cap_net_raw /bin/ping
	use ipv6 && fcaps root:root 4711 cap_net_raw /bin/ping6
	use ipv6 && fcaps root:root 4711 cap_net_raw /usr/sbin/traceroute6

	dodoc INSTALL RELNOTES
	use ipv6 \
		&& dosym ping.8 /usr/share/man/man8/ping6.8 \
		|| rm -f doc/*6.8
	rm -f doc/setkey.8
	doman doc/*.8

	use doc && dohtml doc/*.html
}
