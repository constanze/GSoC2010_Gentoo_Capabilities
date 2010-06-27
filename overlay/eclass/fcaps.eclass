# Copyright 2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# @ECLASS: fcaps.eclass
# @MAINTAINER: Constanze Hausner <ch@gmx.com>
# @BLURB: function to set POSIX file-based capabilities
# @DESCRIPTION:
# This eclass provides a function to set file-based capabilities on binaries.
# Due to probable capability-loss on moving or copying, this happens in
# pkg_postinst-phase (at least for now).

IUSE="filecaps"
DEPEND="filecaps? ( sys-libs/libcap )"

# @FUNCTION: fcaps 
# @USAGE: fcaps {uid:gid} {file-mode} {cap1[,cap2,...]} {file}
# @RETURN: 0 if all okay; non-zero if failure and fallback
# @DESCRIPTION:
# fcaps sets the specified capabilities in the effective and permitted set of
# the given file. In case of failure fcaps sets the given file-mode.
fcaps() {
	local uid_gid=$1
	local perms=$2
	local capset=$3
	local path=$4

	#set owner/group
	chown $uid_gid $path 
	if [ $? -ne 0 ]; then 
		eerror "chown "$uid_gid" "$path" failed."
		return 2
	fi

	#set file-mode including suid
	chmod $perms $path 
	if [ $? -ne 0 ]; then 
		eerror "chmod "$perms" "$path" failed."
		return 3
	fi

	#if filecaps is not enabled all is done
	use !filecaps && return 0

	#set the capability
	setcap "$capset=ep" "$path" &> /dev/null

	#check if the capabilitiy got set correctly
	setcap -v "$capset=ep" "$path" &> /dev/null

	res=$?

	#if caps could be set, remove suid-bit
	if [ $res -eq 0 ]; then
		chmod -s $path
	else
		ewarn "setcap "$capset"=ep "$path" failed."
		ewarn "Check your kernel and filesystem."
		ewarn "Fallback file-mode was set."
	fi

	return $res
}
