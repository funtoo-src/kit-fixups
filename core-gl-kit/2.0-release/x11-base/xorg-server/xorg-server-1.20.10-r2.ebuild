# Distributed under the terms of the GNU General Public License v2

EAPI=7

XORG_EAUTORECONF=yes
XORG_DOC=doc
inherit xorg-3 toolchain-funcs
EGIT_REPO_URI="https://anongit.freedesktop.org/git/xorg/xserver.git"

DESCRIPTION="X.Org X servers"
SLOT="0/${PV}"
KEYWORDS="*"

IUSE_SERVERS="dmx kdrive wayland xephyr xnest xorg xvfb"
IUSE="${IUSE_SERVERS} debug +glamor glvnd ipv6 libressl minimal selinux +udev unwind xcsecurity"

CDEPEND="
	>=app-eselect/eselect-opengl-1.3.0
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )
	>=x11-apps/iceauth-1.0.2
	>=x11-apps/rgb-1.0.3
	>=x11-apps/xauth-1.0.3
	x11-apps/xkbcomp
	>=x11-libs/libdrm-2.4.89
	>=x11-libs/libpciaccess-0.12.901
	>=x11-libs/libXau-1.0.4
	>=x11-libs/libXdmcp-1.0.2
	>=x11-libs/libXfont2-2.0.1
	>=x11-libs/libxkbfile-1.0.4
	>=x11-libs/libxshmfence-1.1
	>=x11-libs/pixman-0.27.2
	>=x11-libs/xtrans-1.3.5
	>=x11-misc/xbitmaps-1.0.1
	>=x11-misc/xkeyboard-config-2.4.1-r3
	dmx? (
		x11-libs/libXt
		>=x11-libs/libdmx-1.0.99.1
		>=x11-libs/libX11-1.1.5
		>=x11-libs/libXaw-1.0.4
		>=x11-libs/libXext-1.0.99.4
		>=x11-libs/libXfixes-5.0
		>=x11-libs/libXi-1.2.99.1
		>=x11-libs/libXmu-1.0.3
		x11-libs/libXrender
		>=x11-libs/libXres-1.0.3
		>=x11-libs/libXtst-1.0.99.2
	)
	glvnd? (
		>=media-libs/mesa-19.1.0-r1[glvnd]
	)
	glamor? (
		media-libs/libepoxy[X]
		>=media-libs/mesa-18[egl,gbm]
		!x11-libs/glamor
	)
	kdrive? (
		>=x11-libs/libXext-1.0.5
		x11-libs/libXv
	)
	xephyr? (
		x11-libs/libxcb[xkb]
		x11-libs/xcb-util
		x11-libs/xcb-util-image
		x11-libs/xcb-util-keysyms
		x11-libs/xcb-util-renderutil
		x11-libs/xcb-util-wm
	)
	!minimal? (
		>=x11-libs/libX11-1.1.5
		>=x11-libs/libXext-1.0.5
		>=media-libs/mesa-18
	)
	udev? ( virtual/libudev:= )
	unwind? ( sys-libs/libunwind )
	wayland? (
		>=dev-libs/wayland-1.3.0
		media-libs/libepoxy
		>=dev-libs/wayland-protocols-1.1
	)
	>=x11-apps/xinit-1.3.3-r1
"

DEPEND="
	${CDEPEND}
	sys-devel/flex
	>=x11-base/xorg-proto-2018.3
	dmx? (
		doc? (
			|| (
				www-client/links
				www-client/lynx
				www-client/w3m
			)
		)
	)
	virtual/opengl
"

RDEPEND="
	${CDEPEND}
	selinux? ( sec-policy/selinux-xserver )
	!x11-drivers/xf86-video-modesetting
"

PDEPEND="xorg? ( >=x11-base/xorg-drivers-$(ver_cut 1-2) )"

REQUIRED_USE="
	!minimal? (
		|| ( ${IUSE_SERVERS} )
	)
	xephyr? ( kdrive )
"

UPSTREAMED_PATCHES=(
)

PATCHES=(
	"${UPSTREAMED_PATCHES[@]}"
	"${FILESDIR}"/${PN}-1.12-unloadsubmodule.patch
	# needed for new eselect-opengl, bug #541232
	"${FILESDIR}"/${PN}-1.18-support-multiple-Files-sections.patch
	# see FL-9875:
	"${FILESDIR}"/xorg-server-1.20.10-rename-xf86Opt-bool-to-boolean.patch
)

pkg_pretend() {
	# older gcc is not supported
	[[ "${MERGE_TYPE}" != "binary" && $(gcc-major-version) -lt 4 ]] && \
		die "Sorry, but gcc earlier than 4.0 will not work for xorg-server."
}

pkg_setup() {
	if use wayland && ! use glamor; then
		ewarn "glamor is necessary for acceleration under Xwayland."
		ewarn "Performance may be unacceptable without it."
	fi
}

src_configure() {
	# localstatedir is used for the log location; we need to override the default
	#	from ebuild.sh
	# sysconfdir is used for the xorg.conf location; same applies
	# NOTE: fop is used for doc generating; and I have no idea if Gentoo
	#	package it somewhere
	XORG_CONFIGURE_OPTIONS=(
		$(use_enable ipv6)
		$(use_enable debug)
		$(use_enable dmx)
		$(use_enable glamor)
		$(use_enable kdrive)
		$(use_enable unwind libunwind)
		$(use_enable wayland xwayland)
		$(use_enable !minimal record)
		$(use_enable !minimal xfree86-utils)
		$(use_enable !minimal dri)
		$(use_enable !minimal dri2)
		$(use_enable !minimal dri3)
		$(use_enable !minimal glamor)
		$(use_enable !minimal glx)
		$(use_enable xcsecurity)
		$(use_enable xephyr)
		$(use_enable xnest)
		$(use_enable xorg)
		$(use_enable xvfb)
		$(use_enable udev config-udev)
		$(use_with doc doxygen)
		$(use_with doc xmlto)
		--disable-suid-wrapper
		--enable-install-setuid
		--disable-systemd-logind
		--enable-libdrm
		--sysconfdir="${EPREFIX}"/etc/X11
		--localstatedir="${EPREFIX}"/var
		--with-fontrootdir="${EPREFIX}"/usr/share/fonts
		--with-xkb-output="${EPREFIX}"/var/lib/xkb
		--disable-config-hal
		--disable-linux-acpi
		--without-dtrace
		--without-fop
		--with-os-vendor=Funtoo
		--with-sha1=libcrypto
		CPP="$(tc-getPROG CPP cpp)"
	)

	xorg-3_src_configure
}

src_install() {
	xorg-3_src_install

	server_based_install

	if ! use minimal && use xorg; then
		# Install xorg.conf.example into docs
		dodoc "${S}"/hw/xfree86/xorg.conf.example
	fi

	newinitd "${FILESDIR}"/xdm-setup.initd-1 xdm-setup
	newinitd "${FILESDIR}"/xdm.initd-14 xdm
	newconfd "${FILESDIR}"/xdm.confd-4 xdm

	# install the @x11-module-rebuild set for Portage
	insinto /usr/share/portage/config/sets
	newins "${FILESDIR}"/xorg-sets.conf xorg.conf

	find "${ED}"/var -type d -empty -delete || die
}

pkg_postinst() {
	# sets up libGL and DRI2 symlinks if needed (ie, on a fresh install)
	eselect opengl set xorg-x11 --use-old
}

pkg_postrm() {
	# Get rid of module dir to ensure opengl-update works properly
	if [[ -z ${REPLACED_BY_VERSION} && -e ${EROOT}/usr/$(get_libdir)/xorg/modules ]]; then
		rm -rf "${EROOT}"/usr/$(get_libdir)/xorg/modules
	fi
}

server_based_install() {
	if ! use xorg; then
		rm "${ED}"/usr/share/man/man1/Xserver.1x \
			"${ED}"/usr/$(get_libdir)/xserver/SecurityPolicy \
			"${ED}"/usr/$(get_libdir)/pkgconfig/xorg-server.pc \
			"${ED}"/usr/share/man/man1/Xserver.1x
	fi
}
