# Copyright 2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: movefile.py 15673 2010-03-02 21:01:30Z zmedico $

__all__ = ['movefile']

import errno
import os as _os
import shutil as _shutil
import stat
import xattr

import portage
from portage import bsd_chflags, _encodings, _os_overrides, _selinux, \
	_unicode_decode, _unicode_func_wrapper, _unicode_module_wrapper
from portage.const import MOVE_BINARY
from portage.localization import _
from portage.process import spawn
from portage.util import writemsg

def movefile(src, dest, newmtime=None, sstat=None, mysettings=None,
		hardlink_candidates=None, encoding=_encodings['fs']):
	"""moves a file from src to dest, preserving all permissions and attributes; mtime will
	be preserved even when moving across filesystems.  Returns true on success and false on
	failure.  Move is atomic."""
	#print "movefile("+str(src)+","+str(dest)+","+str(newmtime)+","+str(sstat)+")"

	if mysettings is None:
		mysettings = portage.settings

	selinux_enabled = mysettings.selinux_enabled()
	if selinux_enabled:
		selinux = _unicode_module_wrapper(_selinux, encoding=encoding)

	lchown = _unicode_func_wrapper(portage.data.lchown, encoding=encoding)
	os = _unicode_module_wrapper(_os,
		encoding=encoding, overrides=_os_overrides)
	shutil = _unicode_module_wrapper(_shutil, encoding=encoding)

	try:
		if not sstat:
			sstat=os.lstat(src)

	except SystemExit as e:
		raise
	except Exception as e:
		print(_("!!! Stating source file failed... movefile()"))
		print("!!!",e)
		return None

	destexists=1
	try:
		dstat=os.lstat(dest)
	except (OSError, IOError):
		dstat=os.lstat(os.path.dirname(dest))
		destexists=0

	if bsd_chflags:
		if destexists and dstat.st_flags != 0:
			bsd_chflags.lchflags(dest, 0)
		# Use normal stat/chflags for the parent since we want to
		# follow any symlinks to the real parent directory.
		pflags = os.stat(os.path.dirname(dest)).st_flags
		if pflags != 0:
			bsd_chflags.chflags(os.path.dirname(dest), 0)

	if destexists:
		if stat.S_ISLNK(dstat[stat.ST_MODE]):
			try:
				os.unlink(dest)
				destexists=0
			except SystemExit as e:
				raise
			except Exception as e:
				pass

	if stat.S_ISLNK(sstat[stat.ST_MODE]):
		try:
			target=os.readlink(src)
			if mysettings and mysettings["D"]:
				if target.find(mysettings["D"])==0:
					target=target[len(mysettings["D"]):]
			if destexists and not stat.S_ISDIR(dstat[stat.ST_MODE]):
				os.unlink(dest)
			if selinux_enabled:
				selinux.symlink(target, dest, src)
			else:
				os.symlink(target,dest)
			lchown(dest,sstat[stat.ST_UID],sstat[stat.ST_GID])
			# utime() only works on the target of a symlink, so it's not
			# possible to perserve mtime on symlinks.
			return os.lstat(dest)[stat.ST_MTIME]
		except SystemExit as e:
			raise
		except Exception as e:
			print(_("!!! failed to properly create symlink:"))
			print("!!!",dest,"->",target)
			print("!!!",e)
			return None

	hardlinked = False
	# Since identical files might be merged to multiple filesystems,
	# so os.link() calls might fail for some paths, so try them all.
	# For atomic replacement, first create the link as a temp file
	# and them use os.rename() to replace the destination.
	if hardlink_candidates:
		head, tail = os.path.split(dest)
		hardlink_tmp = os.path.join(head, ".%s._portage_merge_.%s" % \
			(tail, os.getpid()))
		try:
			os.unlink(hardlink_tmp)
		except OSError as e:
			if e.errno != errno.ENOENT:
				writemsg(_("!!! Failed to remove hardlink temp file: %s\n") % \
					(hardlink_tmp,), noiselevel=-1)
				writemsg("!!! %s\n" % (e,), noiselevel=-1)
				return None
			del e
		for hardlink_src in hardlink_candidates:
			try:
				os.link(hardlink_src, hardlink_tmp)
			except OSError:
				continue
			else:
				try:
					os.rename(hardlink_tmp, dest)
				except OSError as e:
					writemsg(_("!!! Failed to rename %s to %s\n") % \
						(hardlink_tmp, dest), noiselevel=-1)
					writemsg("!!! %s\n" % (e,), noiselevel=-1)
					return None
				hardlinked = True
				break

	renamefailed=1
	if hardlinked:
		renamefailed = False
	if not hardlinked and (selinux_enabled or sstat.st_dev == dstat.st_dev):
		try:
			if selinux_enabled:
				selinux.rename(src, dest)
			else:
				os.rename(src,dest)
			renamefailed=0
		except OSError as e:
			if e.errno != errno.EXDEV:
				# Some random error.
				print(_("!!! Failed to move %(src)s to %(dest)s") % {"src": src, "dest": dest})
				print("!!!",e)
				return None
			# Invalid cross-device-link 'bind' mounted or actually Cross-Device
	if renamefailed:
		didcopy=0
		if stat.S_ISREG(sstat[stat.ST_MODE]):
			try: # For safety copy then move it over.
				if selinux_enabled:
					selinux.copyfile(src, dest + "#new")
					selinux.rename(dest + "#new", dest)
				else:
					#Check for caps
					hasCaps=0
					if xattr.list(src).count("security.capability"):
						#Save caps
						hasCaps=1
						capset=xattr.get(src,"security.capability")
					shutil.copyfile(src,dest+"#new")
					os.rename(dest+"#new",dest)
				didcopy=1
			except EnvironmentError as e:
				print(_("!!! Failed to get capabilities in movefile()"))
				print("!!!",src)
				print("!!!",e)
				return None
			except SystemExit as e:
				raise
			except Exception as e:
				print(_('!!! copy %(src)s -> %(dest)s failed.') % {"src": src, "dest": dest})
				print("!!!",e)
				return None
		else:
			#we don't yet handle special, so we need to fall back to /bin/mv
			a = spawn([MOVE_BINARY, '-f', src, dest], env=os.environ)
			if a != os.EX_OK:
				writemsg(_("!!! Failed to move special file:\n"), noiselevel=-1)
				writemsg(_("!!! '%(src)s' to '%(dest)s'\n") % \
					{"src": _unicode_decode(src, encoding=encoding),
					"dest": _unicode_decode(dest, encoding=encoding)}, noiselevel=-1)
				writemsg("!!! %s\n" % a, noiselevel=-1)
				return None # failure
		try:
			if didcopy:
				if stat.S_ISLNK(sstat[stat.ST_MODE]):
					lchown(dest,sstat[stat.ST_UID],sstat[stat.ST_GID])
				else:
					os.chown(dest,sstat[stat.ST_UID],sstat[stat.ST_GID])
				os.chmod(dest, stat.S_IMODE(sstat[stat.ST_MODE])) # Sticky is reset on chown
				if hasCaps:
					#Apply saved caps
					xattr.set(dest,"security.capability",capset)
				os.unlink(src)
		except EnvironmentError as e:
			print(_("!!! Failed to set capabilities in movefile()"))
			print("!!!",dest)
			print("!!!",e)
			return None
		except SystemExit as e:
			raise
		except Exception as e:
			print(_("!!! Failed to chown/chmod/unlink in movefile()"))
			print("!!!",dest)
			print("!!!",e)
			return None

	# Always use stat_obj[stat.ST_MTIME] for the integral timestamp which
	# is returned, since the stat_obj.st_mtime float attribute rounds *up*
	# if the nanosecond part of the timestamp is 999999881 ns or greater.
	try:
		if hardlinked:
			newmtime = os.stat(dest)[stat.ST_MTIME]
		else:
			# Note: It is not possible to preserve nanosecond precision
			# (supported in POSIX.1-2008 via utimensat) with the IEEE 754
			# double precision float which only has a 53 bit significand.
			if newmtime is not None:
				os.utime(dest, (newmtime, newmtime))
			else:
				newmtime = sstat[stat.ST_MTIME]
				if renamefailed:
					# If rename succeeded then timestamps are automatically
					# preserved with complete precision because the source
					# and destination inode are the same. Otherwise, round
					# down to the nearest whole second since python's float
					# st_mtime cannot be used to preserve the st_mtim.tv_nsec
					# field with complete precision. Note that we have to use
					# stat_obj[stat.ST_MTIME] here because the float
					# stat_obj.st_mtime rounds *up* sometimes.
					os.utime(dest, (newmtime, newmtime))
	except OSError:
		# The utime can fail here with EPERM even though the move succeeded.
		# Instead of failing, use stat to return the mtime if possible.
		try:
			newmtime = os.stat(dest)[stat.ST_MTIME]
		except OSError as e:
			writemsg(_("!!! Failed to stat in movefile()\n"), noiselevel=-1)
			writemsg("!!! %s\n" % dest, noiselevel=-1)
			writemsg("!!! %s\n" % str(e), noiselevel=-1)
			return None

	if bsd_chflags:
		# Restore the flags we saved before moving
		if pflags:
			bsd_chflags.chflags(os.path.dirname(dest), pflags)

	return newmtime
