#!/bin/bash

source tests-common.sh

inherit fcaps

#
# TEST: fcaps
#
test-unknown-caps() {
	local ret=0
	local expected=1
	touch /tmp/fcaps_t
	fcaps root:root 4711 cap_net_rwa /tmp/fcaps_t &> /dev/null
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

ebegin "Testing fcaps with unknown cap"
test-unknown-caps
eend $?

test-known-caps() {
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
	rm -rf /tmp/fcaps_t
	return ${ret}
}

ebegin "Testing fcaps with known cap"
test-known-caps
eend $?

test-unknown-user() {
	local ret=0
	local expected=2
	touch /tmp/fcaps_t
	fcaps hotzenplotz:hotzenplotz 4711 cap_net_raw /tmp/fcaps_t &> /dev/null
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
	fcaps root:root 888 cap_net_raw /tmp/fcaps_t &> /dev/null
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
