# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"
inherit flag-o-matic toolchain-funcs eutils fcaps

DESCRIPTION="A Tool for network monitoring and data acquisition"
HOMEPAGE="http://www.tcpdump.org/"
SRC_URI="http://www.tcpdump.org/release/${P}.tar.gz
		http://www.jp.tcpdump.org/release/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux"
IUSE="+chroot smi ssl ipv6 -samba suid test"

RDEPEND="net-libs/libpcap
	smi? ( net-libs/libsmi )
	ssl? ( >=dev-libs/openssl-0.9.6m )"
DEPEND="${RDEPEND}
	test? ( app-arch/sharutils
		dev-lang/perl )"

pkg_setup() {
	if use samba ; then
		ewarn
		ewarn "CAUTION !!! CAUTION !!! CAUTION"
		ewarn
		ewarn "You're about to compile tcpdump with samba printing support"
		ewarn "Upstream tags it as 'possibly-buggy SMB printer'"
		ewarn "So think twice whether this is fine with you"
		ewarn
		ewarn "CAUTION !!! CAUTION !!! CAUTION"
		ewarn
	fi
	
	if use suid && use filecaps ; then
		ewarn
		ewarn "CAUTION !!! CAUTION !!! CAUTION"
		ewarn
		ewarn "You're about to compile tcpdump with suid _and_ filecaps support."
		ewarn "Use of filecaps will normally lead to removed suid-bit"
		ewarn "which might not be what you want."
		ewarn
		ewarn "CAUTION !!! CAUTION !!! CAUTION"
		ewarn
	fi
	enewgroup tcpdump
	enewuser tcpdump -1 -1 -1 tcpdump
}

src_configure() {
	# tcpdump needs some optymalization. see bug #108391
	( ! is-flag -O? || is-flag -O0 ) && append-flags -O2

	replace-flags -O[3-9] -O2
	filter-flags -finline-functions

	econf --with-user=tcpdump \
		$(use_with ssl crypto) \
		$(use_with smi) \
		$(use_enable ipv6) \
		$(use_enable samba smb) \
		$(use_with chroot chroot /var/lib/tcpdump)
}

src_compile() {
	make CCOPT="$CFLAGS" || die "make failed"
}

src_test() {
	sed '/^\(espudp1\|eapon1\)/d;' -i tests/TESTLIST
	make check || die "tests failed"
}

src_install() {
	dobin tcpdump || die
	doman tcpdump.1 || die
	dodoc *.awk || die
	dodoc CHANGES CREDITS README || die

	if use chroot; then
		keepdir /var/lib/tcpdump
		fperms 700 /var/lib/tcpdump
		fowners tcpdump:tcpdump /var/lib/tcpdump
	fi
}

pkg_postinst() {
	
	if use suid; then
		fcaps root:tcpdump 4110 cap_net_raw /usr/bin/tcpdump 0
	else
		fcaps root:root 755 cap_net_raw /usr/bin/tcpdump 0
	fi

	use suid && elog "To let normal users run tcpdump add them into tcpdump group."
	if use filecaps; then
		elog "To let normal users run tcpdump, you have to use pam_cap"
		elog "and add the users to /etc/security/capability.conf"
		elog "with cap_net_raw."
		elog "For a detailed guide see:"
		elog "http://wiki.github.com/constanze/GSoC2010_Gentoo_Capabilities/pam_cap-on-gentoo"
	fi
}
