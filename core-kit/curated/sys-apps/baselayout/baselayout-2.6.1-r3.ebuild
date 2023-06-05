# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit versionator prefix

DESCRIPTION="Filesystem baselayout and init scripts"
SRC_URI="https://gitweb.gentoo.org/proj/${PN}.git/snapshot/baselayout-2.6.tar.bz2"
KEYWORDS="*"

LICENSE="GPL-2"
SLOT="0"
IUSE="build kernel_FreeBSD kernel_linux +split-usr"
S="${WORKDIR}"/baselayout-2.6

pkg_preinst() {
	# This is written in src_install (so it's in CONTENTS), but punt all
	# pending updates to avoid user having to do etc-update (and make the
	# pkg_postinst logic simpler).
	rm -f "${EROOT}"/etc/._cfg????_gentoo-release

	if use build && [ $ROOT != "/" ]; then
		if use split-usr ; then
			emake -C "${ED}/usr/share/${PN}" DESTDIR="${EROOT}" layout
		else
			emake -C "${ED}/usr/share/${PN}" DESTDIR="${EROOT}" layout-usrmerge
		fi
	fi
	rm -f "${ED}"/usr/share/${PN}/Makefile
}

src_prepare() {
	default
	if use prefix; then
		hprefixify -e "/EUID/s,0,${EUID}," -q '"' etc/profile
		hprefixify etc/{env.d/50baselayout,shells} share.Linux/passwd
		echo PATH=/usr/bin:/bin >> etc/env.d/99host
		echo ROOTPATH=/usr/sbin:/sbin:/usr/bin:/bin >> etc/env.d/99host
	fi

	for libdir in lib; do
		ldpaths+=":${EPREFIX}/${libdir}:${EPREFIX}/usr/${libdir}"
		ldpaths+=":${EPREFIX}/usr/local/${libdir}"
	done
	echo "LDPATH='${ldpaths#:}'" >> etc/env.d/50baselayout

	# rc-scripts version for testing of features that *should* be present
	echo "Funtoo Linux 1.4" > etc/gentoo-release
}

src_install() {
	emake \
		OS=$(usex kernel_FreeBSD BSD Linux) \
		DESTDIR="${ED}" \
		install
	dodoc ChangeLog

	# need the makefile in pkg_preinst
	insinto /usr/share/${PN}
	doins Makefile
	rm -f ${D}/etc/hosts
	cat > ${D}/etc/os-release << EOF
ID="funtoo"
NAME="Funtoo"
PRETTY_NAME="Funtoo Linux"
ANSI_COLOR="0;34"
HOME_URL="https://www.funtoo.org"
BUG_REPORT_URL="https://bugs.funtoo.org"
EOF
	cat > ${D}/etc/env.d/00basic << EOF
# /etc/env.d/00basic
# Do not edit this file - ensure language settings are sane.

LANG="en_US.UTF-8"
LC_COLLATE="POSIX"
EOF
	insinto /etc
	newins ${FILESDIR}/profile-2.6.1-r2 profile || die
	insinto /usr/share/baselayout
	doins ${FILESDIR}/fstab
}

pkg_postinst() {
	local x

	# We installed some files to /usr/share/baselayout instead of /etc to stop
	# (1) overwriting the user's settings
	# (2) screwing things up when attempting to merge files
	# (3) accidentally packaging up personal files with quickpkg
	# If they don't exist then we install them
	for x in master.passwd passwd shadow group fstab ; do
		[ -e "${EROOT}etc/${x}" ] && continue
		[ -e "${EROOT}usr/share/baselayout/${x}" ] || continue
		cp -p "${EROOT}usr/share/baselayout/${x}" "${EROOT}"etc
	done

	# Force shadow permissions to not be world-readable #260993
	for x in shadow ; do
		[ -e "${EROOT}etc/${x}" ] && chmod o-rwx "${EROOT}etc/${x}"
	done

	# Take care of the etc-update for the user
	if [ -e "${EROOT}"etc/._cfg0000_gentoo-release ] ; then
		mv "${EROOT}"etc/._cfg0000_gentoo-release "${EROOT}"etc/gentoo-release
	fi

	# whine about users that lack passwords #193541
	if [[ -e "${EROOT}"etc/shadow ]] ; then
		local bad_users=$(sed -n '/^[^:]*::/s|^\([^:]*\)::.*|\1|p' "${EROOT}"/etc/shadow)
		if [[ -n ${bad_users} ]] ; then
			echo
			ewarn "The following users lack passwords!"
			ewarn ${bad_users}
		fi
	fi

	# whine about users with invalid shells #215698
	if [[ -e "${EROOT}"etc/passwd ]] ; then
		local bad_shells=$(awk -F: 'system("test -e " $7) { print $1 " - " $7}' "${EROOT}"etc/passwd | sort)
		if [[ -n ${bad_shells} ]] ; then
			echo
			ewarn "The following users have non-existent shells!"
			ewarn "${bad_shells}"
		fi
	fi

	# https://bugs.gentoo.org/361349
	if use kernel_linux; then
		mkdir -p "${EROOT}"run

		local found fstype mountpoint
		while read -r _ mountpoint fstype _; do
		[[ ${mountpoint} = /run ]] && [[ ${fstype} = tmpfs ]] && found=1
		done < "${ROOT}"proc/mounts
		[[ -z ${found} ]] &&
			ewarn "You should reboot now to get /run mounted with tmpfs!"
	fi

	for x in ${REPLACING_VERSIONS}; do
		if ! version_is_at_least 2.4 ${x}; then
			ewarn "After updating ${EROOT}etc/profile, please run"
			ewarn "env-update && . /etc/profile"
		fi

		if ! version_is_at_least 2.6 ${x}; then
			ewarn "Please run env-update then log out and back in to"
			ewarn "update your path."
		fi
		# clean up after 2.5 typos
		# https://bugs.gentoo.org/show_bug.cgi?id=656380
		if [[ ${x} == 2.5 ]]; then
			rm -fr "${EROOT}{,usr"
		fi
	done
}

