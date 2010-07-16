#!/bin/bash

source tests-common.sh

inherit fcaps

#
# TEST: fcaps
#
test-unknown-caps_suid() {
	local ret=0
	local expected=1
	touch /tmp/fcaps_t
	fcaps root:root 4711 cap_net_rwa /tmp/fcaps_t 1 &> /dev/null
	local actual=$?
	
	if [[ ${actual} != ${expected} ]] ; then
		eerror "Failure: Expected: EXIT_CODE ${expected} != Actual: ${actual}"
		((++ret))
	fi
	local fstat=`stat -c %a /tmp/fcaps_t`
	if [[ ${fstat} != 4711 ]] ; then
		eerror "Failure: Expected: file-mode 4711 != Actual: ${fstat}"
		((++ret))
	fi
	rm -rf /tmp/fcaps_t
	return ${ret}
}

ebegin "Testing fcaps with unknown cap and suid-fallback"
test-unknown-caps_suid
eend $?

test-unknown-caps_nosuid() {
	local ret=0
	local expected=1
	touch /tmp/fcaps_t
	fcaps root:root 711 cap_net_rwa /tmp/fcaps_t 1 &> /dev/null
	local actual=$?
	
	if [[ ${actual} != ${expected} ]] ; then
		eerror "Failure: Expected: EXIT_CODE ${expected} != Actual: ${actual}"
		((++ret))
	fi
	local fstat=`stat -c %a /tmp/fcaps_t`
	if [[ ${fstat} != 711 ]] ; then
		eerror "Failure: Expected: file-mode 711 != Actual: ${fstat}"
		((++ret))
	fi
	rm -rf /tmp/fcaps_t
	return ${ret}
}

ebegin "Testing fcaps with unknown cap and nosuid-fallback"
test-unknown-caps_nosuid
eend $?

test-known-caps_setmode_ep() {
	local ret=0
	local expected=0
	touch /tmp/fcaps_t
	fcaps root:root 4711 cap_net_raw /tmp/fcaps_t 1 &> /dev/null
	local actual=$?
	
	if [[ ${actual} != ${expected} ]] ; then
		eerror "Failure: Expected: EXIT_CODE ${expected} != Actual: ${actual}"
		((++ret))
	fi
	local fstat=`stat -c %a /tmp/fcaps_t`
	if [[ ${fstat} != 711 ]] ; then
		eerror "Failure: Expected: file-mode 711 != Actual: ${fstat}"
		((++ret))
	fi
	
	local caps=`getcap /tmp/fcaps_t`
	if [[ ${caps} != "/tmp/fcaps_t = cap_net_raw+ep" ]] ; then
		eerror "Failure: Expected: /tmp/fcaps_t = cap_net_raw+ep != Actual: ${caps}"
		((++ret))
	fi
	
	rm -rf /tmp/fcaps_t
	return ${ret}
}

ebegin "Testing fcaps with known cap and setmode=ep"
test-known-caps_setmode_ep
eend $?

test-known-caps_setmode_not_provided() {
	local ret=0
	local expected=0
	touch /tmp/fcaps_t
	fcaps root:root 4711 cap_net_raw /tmp/fcaps_t &> /dev/null
	local actual=$?
	
	if [[ ${actual} != ${expected} ]] ; then
		eerror "Failure: Expected: EXIT_CODE ${expected} != Actual: ${actual}"
		((++ret))
	fi
	local fstat=`stat -c %a /tmp/fcaps_t`
	if [[ ${fstat} != 711 ]] ; then
		eerror "Failure: Expected: file-mode 711 != Actual: ${fstat}"
		((++ret))
	fi
	
	local caps=`getcap /tmp/fcaps_t`
	if [[ ${caps} != "/tmp/fcaps_t = cap_net_raw+ep" ]] ; then
		eerror "Failure: Expected: /tmp/fcaps_t = cap_net_raw+ep != Actual: ${caps}"
		((++ret))
	fi
	
	rm -rf /tmp/fcaps_t
	return ${ret}
}

ebegin "Testing fcaps with known cap and no setmode provided"
test-known-caps_setmode_not_provided
eend $?

test-known-caps_setmode_ei() {
	local ret=0
	local expected=0
	touch /tmp/fcaps_t
	fcaps root:root 4711 cap_net_raw /tmp/fcaps_t 0 &> /dev/null
	local actual=$?
	
	if [[ ${actual} != ${expected} ]] ; then
		eerror "Failure: Expected: EXIT_CODE ${expected} != Actual: ${actual}"
		((++ret))
	fi
	local fstat=`stat -c %a /tmp/fcaps_t`
	if [[ ${fstat} != 711 ]] ; then
		eerror "Failure: Expected: file-mode 711 != Actual: $fstat}"
		((++ret))
	fi
	
	local caps=`getcap /tmp/fcaps_t`
	if [[ ${caps} != "/tmp/fcaps_t = cap_net_raw+ei" ]] ; then
		eerror "Failure: Expected: /tmp/fcaps_t = cap_net_raw+ei != Actual: ${caps}"
		((++ret))
	fi
	
	rm -rf /tmp/fcaps_t
	return ${ret}
}

ebegin "Testing fcaps with known cap and setmode=ei"
test-known-caps_setmode_ei
eend $?

test-unknown-user() {
	local ret=0
	local expected=2
	touch /tmp/fcaps_t
	fcaps hotzenplotz:hotzenplotz 4711 cap_net_raw /tmp/fcaps_t 1 &> /dev/null
	local actual=$?
	
	if [[ ${actual} != ${expected} ]] ; then
		eerror "Failure: Expected: EXIT_CODE ${expected} != Actual: ${actual}"
		((++ret))
	fi
	rm -rf /tmp/fcaps_t
	return ${ret}
}

ebegin "Testing fcaps with unknown user"
test-unknown-user
eend $?

test-unknown-filemode() {
	local ret=0
	local expected=3
	touch /tmp/fcaps_t
	fcaps root:root 888 cap_net_raw /tmp/fcaps_t 1 &> /dev/null
	local actual=$?
	
	if [[ ${actual} != ${expected} ]] ; then
		eerror "Failure: Expected: EXIT_CODE ${expected} != Actual: ${actual}"
		((++ret))
	fi
	rm -rf /tmp/fcaps_t
	return ${ret}
}

ebegin "Testing fcaps with unknown filemode"
test-unknown-filemode
eend $?

test-missing-libcap() {
	local ret=0
	local expected=4
	touch /tmp/fcaps_t
	mv /sbin/setcap /sbin/setcap_
	fcaps root:root 4711 cap_net_raw /tmp/fcaps_t 1 &> /dev/null
	local actual=$?
	
	if [[ ${actual} != ${expected} ]] ; then
		eerror "Failure: Expected: EXIT_CODE ${expected} != Actual: ${actual}"
		((++ret))
	fi
	rm -rf /tmp/fcaps_t
	mv /sbin/setcap_ /sbin/setcap
	return ${ret}
}

ebegin "Testing fcaps with missing libcap"
test-missing-libcap
eend $?
