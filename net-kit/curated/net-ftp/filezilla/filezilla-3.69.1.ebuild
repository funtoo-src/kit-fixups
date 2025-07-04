# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools wxwidgets xdg

DESCRIPTION="FTP client with lots of useful features and an intuitive interface"
HOMEPAGE="https://filezilla-project.org/"
SRC_URI="https://dl2.cdn.filezilla-project.org/client/FileZilla_3.69.1_src.tar.xz?h=KoTPvV6OVm8ildqiCwMKSg&x=1750901727 -> FileZilla_3.69.1_src.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="dbus nls test"
RESTRICT="!test? ( test )"

# pugixml 1.7 minimal dependency is for c++11 proper configuration
RDEPEND="
	>=dev-libs/nettle-3.1:=
	>=dev-db/sqlite-3.7
	>=dev-libs/libfilezilla-0.48.1:=
	>=dev-libs/pugixml-1.7
	>=net-libs/gnutls-3.5.7
	x11-libs/wxGTK
	x11-misc/xdg-utils
	dbus? ( sys-apps/dbus )"
DEPEND="${RDEPEND}
	test? ( >=dev-util/cppunit-1.13.0 )"
BDEPEND="
	virtual/pkgconfig
	>=sys-devel/libtool-1.4
	nls? ( >=sys-devel/gettext-0.11 )"

src_prepare() {
	# Removes debug
	sed -i "s/AX_APPEND_FLAG(-g, C.*FLAGS)//g" "${S}"/configure.ac
	
	# Metainfo patch
	sed -i "s/appdatadir = \$\(datadir\)\/appdata/appdatadir = \$\(datadir\)\/metainfo/g" "${S}"/data/Makefile.am

	# Desktop file patch
	grep "MimeType=" data/filezilla.desktop || echo "MimeType=x-scheme-handler/ftp;" >> data/filezilla.desktop

	default
	eautoreconf
}

src_configure() {
	local myeconfargs=(
		--disable-autoupdatecheck
		--with-pugixml=system
		$(use_enable nls locales)
		$(use_with dbus)
	)
	econf "${myeconfargs[@]}"
}

src_install() {
	default

	# no static archives
	find "${ED}" -name '*.la' -delete || die
}