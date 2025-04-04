# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: gnome3-utils.eclass
# @MAINTAINER:
# gnome@gentoo.org
# @SUPPORTED_EAPIS: 0 1 2 3 4 5 6 7
# @BLURB: Auxiliary functions commonly used by Gnome packages.
# @DESCRIPTION:
# This eclass provides a set of auxiliary functions needed by most Gnome
# packages. It may be used by non-Gnome packages as needed for handling various
# Gnome stack related functions such as:
#  * GSettings schemas management
#  * GConf schemas management
#  * scrollkeeper (old Gnome help system) management

[[ ${EAPI:-0} == [012345] ]] && inherit multilib
[[ ${EAPI:-0} == [0123456] ]] && inherit eutils
inherit xdg-utils

case "${EAPI:-0}" in
	0|1|2|3|4|5|6|7) ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

# @ECLASS-VARIABLE: GCONFTOOL_BIN
# @INTERNAL
# @DESCRIPTION:
# Path to gconftool-2
: ${GCONFTOOL_BIN:="/usr/bin/gconftool-2"}

# @ECLASS-VARIABLE: SCROLLKEEPER_DIR
# @INTERNAL
# @DESCRIPTION:
# Directory where scrollkeeper-update should do its work
: ${SCROLLKEEPER_DIR:="/var/lib/scrollkeeper"}

# @ECLASS-VARIABLE: SCROLLKEEPER_UPDATE_BIN
# @INTERNAL
# @DESCRIPTION:
# Path to scrollkeeper-update
: ${SCROLLKEEPER_UPDATE_BIN:="/usr/bin/scrollkeeper-update"}

# @ECLASS-VARIABLE: GLIB_COMPILE_SCHEMAS
# @INTERNAL
# @DESCRIPTION:
# Path to glib-compile-schemas
: ${GLIB_COMPILE_SCHEMAS:="/usr/bin/glib-compile-schemas"}

# @ECLASS-VARIABLE: GNOME3_ECLASS_SCHEMAS
# @INTERNAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# List of GConf schemas provided by the package

# @ECLASS-VARIABLE: GNOME3_ECLASS_ICONS
# @INTERNAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# List of icons provided by the package

# @ECLASS-VARIABLE: GNOME3_ECLASS_SCROLLS
# @INTERNAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# List of scrolls (documentation files) provided by the package

# @ECLASS-VARIABLE: GNOME3_ECLASS_GLIB_SCHEMAS
# @INTERNAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# List of GSettings schemas provided by the package

# @ECLASS-VARIABLE: GNOME3_ECLASS_GDK_PIXBUF_LOADERS
# @INTERNAL
# @DEFAULT_UNSET
# @DESCRIPTION:
# List of gdk-pixbuf loaders provided by the package


# @FUNCTION: gnome3_environment_reset
# @DESCRIPTION:
# Reset various variables inherited from root's evironment to a reasonable
# default for ebuilds to help avoid access violations and test failures.
gnome3_environment_reset() {
	xdg_environment_reset

	# Respected by >=glib-2.30.1-r1
	export G_HOME="${T}"

	# GST_REGISTRY is to work around gst utilities trying to read/write /root
	export GST_REGISTRY="${T}/registry.xml"

	# Ensure we don't rely on dconf/gconf while building, bug #511946
	export GSETTINGS_BACKEND="memory"

	if has ${EAPI:-0} 6 7; then
		# Try to cover the packages honoring this variable, bug #508124
		export GST_INSPECT="$(type -P true)"

		# Stop relying on random DISPLAY variable values, bug #534312
		unset DISPLAY
	fi
}

# @FUNCTION: gnome3_gconf_savelist
# @DESCRIPTION:
# Find the GConf schemas that are about to be installed and save their location
# in the GNOME3_ECLASS_SCHEMAS environment variable.
# This function should be called from pkg_preinst.
gnome3_gconf_savelist() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && ED="${D}"
	pushd "${ED}" > /dev/null || die
	export GNOME3_ECLASS_SCHEMAS=$(find 'etc/gconf/schemas/' -name '*.schemas' 2> /dev/null)
	popd > /dev/null || die
}

# @FUNCTION: gnome3_gconf_install
# @DESCRIPTION:
# Applies any schema files installed by the current ebuild to Gconf's database
# using gconftool-2.
# This function should be called from pkg_postinst.
gnome3_gconf_install() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}${GCONFTOOL_BIN}"

	if [[ ! -x "${updater}" ]]; then
		debug-print "${updater} is not executable"
		return
	fi

	if [[ -z "${GNOME3_ECLASS_SCHEMAS}" ]]; then
		debug-print "No GNOME 2 GConf schemas found"
		return
	fi

	# We are ready to install the GCONF Scheme now
	unset GCONF_DISABLE_MAKEFILE_SCHEMA_INSTALL
	export GCONF_CONFIG_SOURCE="$("${updater}" --get-default-source | sed "s;:/;:${ROOT};")"

	einfo "Installing GNOME 2 GConf schemas"

	local F
	for F in ${GNOME3_ECLASS_SCHEMAS}; do
		if [[ -e "${EROOT}${F}" ]]; then
			debug-print "Installing schema: ${F}"
			"${updater}" --makefile-install-rule "${EROOT}${F}" 1>/dev/null
		fi
	done

	# have gconf reload the new schemas
	pids=$(pgrep -x gconfd-2)
	if [[ $? == 0 ]] ; then
		ebegin "Reloading GConf schemas"
		kill -HUP ${pids}
		eend $?
	fi
}

# @FUNCTION: gnome3_gconf_uninstall
# @DESCRIPTION:
# Removes schema files previously installed by the current ebuild from Gconf's
# database.
gnome3_gconf_uninstall() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}${GCONFTOOL_BIN}"

	if [[ ! -x "${updater}" ]]; then
		debug-print "${updater} is not executable"
		return
	fi

	if [[ -z "${GNOME3_ECLASS_SCHEMAS}" ]]; then
		debug-print "No GNOME 2 GConf schemas found"
		return
	fi

	unset GCONF_DISABLE_MAKEFILE_SCHEMA_INSTALL
	export GCONF_CONFIG_SOURCE="$("${updater}" --get-default-source | sed "s;:/;:${ROOT};")"

	einfo "Uninstalling GNOME 2 GConf schemas"

	local F
	for F in ${GNOME3_ECLASS_SCHEMAS}; do
		if [[ -e "${EROOT}${F}" ]]; then
			debug-print "Uninstalling gconf schema: ${F}"
			"${updater}" --makefile-uninstall-rule "${EROOT}${F}" 1>/dev/null
		fi
	done

	# have gconf reload the new schemas
	pids=$(pgrep -x gconfd-2)
	if [[ $? == 0 ]] ; then
		ebegin "Reloading GConf schemas"
		kill -HUP ${pids}
		eend $?
	fi
}

# @FUNCTION: gnome3_omf_fix
# @DESCRIPTION:
# Workaround applied to Makefile rules in order to remove redundant
# calls to scrollkeeper-update and sandbox violations.
# This function should be called from src_prepare.
gnome3_omf_fix() {
	local omf_makefiles filename

	omf_makefiles="$@"

	if [[ -f ${S}/omf.make ]] ; then
		omf_makefiles="${omf_makefiles} ${S}/omf.make"
	fi

	if [[ -f ${S}/gnome-doc-utils.make ]] ; then
		omf_makefiles="${omf_makefiles} ${S}/gnome-doc-utils.make"
	fi

	# testing fixing of all makefiles found
	# The sort is important to ensure .am is listed before the respective .in for
	# maintainer mode regeneration not kicking in due to .am being newer than .in
	for filename in $(find "${S}" -name "Makefile.in" -o -name "Makefile.am" |sort) ; do
		omf_makefiles="${omf_makefiles} ${filename}"
	done

	ebegin "Fixing OMF Makefiles"

	local retval=0
	local fails=( )

	for omf in ${omf_makefiles} ; do
		sed -i -e 's:scrollkeeper-update:true:' "${omf}"
		retval=$?

		if [[ $retval -ne 0 ]] ; then
			debug-print "updating of ${omf} failed"

			# Add to the list of failures
			fails[$(( ${#fails[@]} + 1 ))]=$omf

			retval=2
		fi
	done

	eend $retval

	for f in "${fails[@]}" ; do
		eerror "Failed to update OMF Makefile $f"
	done
}

# @FUNCTION: gnome3_scrollkeeper_savelist
# @DESCRIPTION:
# Find the scrolls that are about to be installed and save their location
# in the GNOME3_ECLASS_SCROLLS environment variable.
# This function should be called from pkg_preinst.
gnome3_scrollkeeper_savelist() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && ED="${D}"
	pushd "${ED}" > /dev/null || die
	export GNOME3_ECLASS_SCROLLS=$(find 'usr/share/omf' -type f -name "*.omf" 2> /dev/null)
	popd > /dev/null || die
}

# @FUNCTION: gnome3_scrollkeeper_update
# @DESCRIPTION:
# Updates the global scrollkeeper database.
# This function should be called from pkg_postinst and pkg_postrm.
gnome3_scrollkeeper_update() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}${SCROLLKEEPER_UPDATE_BIN}"

	if [[ ! -x "${updater}" ]] ; then
		debug-print "${updater} is not executable"
		return
	fi

	if [[ -z "${GNOME3_ECLASS_SCROLLS}" ]]; then
		debug-print "No scroll cache to update"
		return
	fi

	ebegin "Updating scrollkeeper database ..."
	"${updater}" -q -p "${EROOT}${SCROLLKEEPER_DIR}"
	eend $?
}

# @FUNCTION: gnome3_schemas_savelist
# @DESCRIPTION:
# Find if there is any GSettings schema to install and save the list in
# GNOME3_ECLASS_GLIB_SCHEMAS variable. This is only necessary for eclass
# implementations that call gnome3_schemas_update conditionally.
# This function should be called from pkg_preinst.
gnome3_schemas_savelist() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && ED="${D}"
	pushd "${ED}" > /dev/null || die
	export GNOME3_ECLASS_GLIB_SCHEMAS=$(find 'usr/share/glib-2.0/schemas' -name '*.gschema.xml' 2>/dev/null)
	popd > /dev/null || die
}

# @FUNCTION: gnome3_schemas_update
# @USAGE: gnome3_schemas_update
# @DESCRIPTION:
# Updates GSettings schemas.
# This function should be called from pkg_postinst and pkg_postrm.
gnome3_schemas_update() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}${GLIB_COMPILE_SCHEMAS}"

	if [[ ! -x ${updater} ]]; then
		debug-print "${updater} is not executable"
		return
	fi

	ebegin "Updating GSettings schemas"
	${updater} --allow-any-name "$@" "${EROOT%/}/usr/share/glib-2.0/schemas" &>/dev/null
	eend $?
}

# @FUNCTION: gnome3_gdk_pixbuf_savelist
# @DESCRIPTION:
# Find if there is any gdk-pixbuf loader to install and save the list in
# GNOME3_ECLASS_GDK_PIXBUF_LOADERS variable.
# This function should be called from pkg_preinst.
gnome3_gdk_pixbuf_savelist() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && ED="${D}"
	pushd "${ED}" > /dev/null || die
	export GNOME3_ECLASS_GDK_PIXBUF_LOADERS=$(find usr/lib*/gdk-pixbuf-2.0 -type f 2>/dev/null)
	popd > /dev/null || die
}

# @FUNCTION: gnome3_gdk_pixbuf_update
# @USAGE: gnome3_gdk_pixbuf_update
# @DESCRIPTION:
# Updates gdk-pixbuf loader cache if GNOME3_ECLASS_GDK_PIXBUF_LOADERS has some.
# This function should be called from pkg_postinst and pkg_postrm.
gnome3_gdk_pixbuf_update() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}/usr/bin/${CHOST}-gdk-pixbuf-query-loaders"

	if [[ ! -x ${updater} ]]; then
		updater="${EROOT}/usr/bin/gdk-pixbuf-query-loaders"
	fi

	if [[ ! -x ${updater} ]]; then
		debug-print "${updater} is not executable"
		return
	fi

	if [[ -z ${GNOME3_ECLASS_GDK_PIXBUF_LOADERS} ]]; then
		debug-print "gdk-pixbuf loader cache does not need an update"
		return
	fi

	ebegin "Updating gdk-pixbuf loader cache"
	local tmp_file=$(emktemp)
	${updater} 1> "${tmp_file}" &&
	chmod 0644 "${tmp_file}" &&
	cp -f "${tmp_file}" "${EROOT}/usr/$(get_libdir)/gdk-pixbuf-2.0/2.10.0/loaders.cache" &&
	rm "${tmp_file}" # don't replace this with mv, required for SELinux support
	eend $?
}

# @FUNCTION: gnome3_query_immodules_gtk2
# @USAGE: gnome3_query_immodules_gtk2
# @DESCRIPTION:
# Updates gtk2 immodules/gdk-pixbuf loaders listing.
gnome3_query_immodules_gtk2() {
	local updater=${EPREFIX}/usr/bin/${CHOST}-gtk-query-immodules-2.0
	[[ ! -x ${updater} ]] && updater=${EPREFIX}/usr/bin/gtk-query-immodules-2.0

	ebegin "Updating gtk2 input method module cache"
	GTK_IM_MODULE_FILE="${EROOT}usr/$(get_libdir)/gtk-2.0/2.10.0/immodules.cache" \
		"${updater}" --update-cache
	eend $?
}

# @FUNCTION: gnome3_update_immodules_cache_gtk3
# @USAGE: gnome3_update_immodules_cache_gtk3
# @DESCRIPTION:
# Updates gtk3 immodules/gdk-pixbuf loaders listing.
gnome3_update_immodules_cache_gtk3() {
	local updater=${EPREFIX}/usr/bin/gtk-query-immodules-3.0
	[ ! -e "$updater" ] && die "Updater $updater not found."
	ebegin "Updating gtk3 input method module cache"
	GTK_IM_MODULE_FILE="${EROOT}/usr/$(get_libdir)/gtk-3.0/3.0.0/immodules.cache"
	output="$(${updater} --update-cache 2>&1)"
	if [ $? -ne 0 ]; then
		ewarn "There were some problems updating the immodules cache: $output"
		ewarn "These problems may be transient and due to temporary missing symbols."
	else
		einfo "Immodules cache update success."
	fi
}

# @FUNCTION: gnome3_giomodule_cache_update
# @USAGE: gnome3_giomodule_cache_update
# @DESCRIPTION:
# Updates glib's gio modules cache.
# This function should be called from pkg_postinst and pkg_postrm.
gnome3_giomodule_cache_update() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && EROOT="${ROOT}"
	local updater="${EROOT}/usr/bin/${CHOST}-gio-querymodules"

	if [[ ! -x ${updater} ]]; then
		updater="${EROOT}/usr/bin/gio-querymodules"
	fi

	if [[ ! -x ${updater} ]]; then
		debug-print "${updater} is not executable"
		return
	fi

	ebegin "Updating GIO modules cache"
	${updater} "${EROOT%/}"/usr/$(get_libdir)/gio/modules
	eend $?
}

# @FUNCTION: gnome3_disable_deprecation_warning
# @DESCRIPTION:
# Disable deprecation warnings commonly found in glib based packages.
# Should be called from src_prepare.
gnome3_disable_deprecation_warning() {
	local retval=0
	local fails=( )
	local makefile

	ebegin "Disabling deprecation warnings"
	# The sort is important to ensure .am is listed before the respective .in for
	# maintainer mode regeneration not kicking in due to .am being newer than .in
	while read makefile ; do
		if ! grep -qE "(DISABLE_DEPRECATED|GSEAL_ENABLE)" "${makefile}"; then
			continue
		fi

		LC_ALL=C sed -r -i \
			-e 's:-D[A-Z_]+_DISABLE_DEPRECATED:$(/bin/true):g' \
			-e 's:-DGSEAL_ENABLE(=[A-Za-z0-9_]*)?:$(/bin/true):g' \
			-i "${makefile}"

		if [[ $? -ne 0 ]]; then
			# Add to the list of failures
			fails+=( "${makefile}" )
			retval=2
		fi
	done < <(find "${S}" -name "Makefile.in" \
		-o -name "Makefile.am" -o -name "Makefile.decl" \
		| sort; [[ -f "${S}"/configure ]] && echo configure)
# TODO: sedding configure.ac can trigger maintainer mode; bug #439602
#		-o -name "configure.ac" -o -name "configure.in" \
#		| sort; echo configure)
	eend ${retval}

	for makefile in "${fails[@]}" ; do
		ewarn "Failed to disable deprecation warnings in ${makefile}"
	done
}

case ${EAPI:-0} in
0|1|2|3|4|5|6)

# @FUNCTION: gnome3_icon_savelist
# @DESCRIPTION:
# Find the icons that are about to be installed and save their location
# in the GNOME3_ECLASS_ICONS environment variable. This is only
# necessary for eclass implementations that call
# gnome3_icon_cache_update conditionally.
# This function should be called from pkg_preinst.
gnome3_icon_savelist() {
	has ${EAPI:-0} 0 1 2 && ! use prefix && ED="${D}"
	pushd "${ED}" > /dev/null || die
	export GNOME3_ECLASS_ICONS=$(find 'usr/share/icons' -maxdepth 1 -mindepth 1 -type d 2> /dev/null)
	popd > /dev/null || die
}

# @FUNCTION: gnome3_icon_cache_update
# @DESCRIPTION:
# Updates Gtk+ icon cache files under /usr/share/icons.
# Deprecated. Please use xdg_icon_cache_update from xdg-utils.eclass
gnome3_icon_cache_update() {
	xdg_icon_cache_update
}

;;
esac
