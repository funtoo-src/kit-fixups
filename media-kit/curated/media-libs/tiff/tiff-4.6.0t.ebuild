# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools libtool

DESCRIPTION="Tag Image File Format (TIFF) library"
HOMEPAGE="http://www.libtiff.org"
SRC_URI="http://www.libtiff.org/downloads/${P}.tar.gz"

LICENSE="libtiff"
SLOT="0"
KEYWORDS="*"
IUSE="+cxx jbig jpeg lzma static-libs test webp zlib zstd"

RDEPEND="
	jbig? ( >=media-libs/jbigkit-2.1:= )
	jpeg? ( >=virtual/jpeg-0-r2:0= )
	lzma? ( >=app-arch/xz-utils-5.0.5-r1 )
	webp? ( media-libs/libwebp:= )
	zlib? ( >=sys-libs/zlib-1.2.8-r1 )
	zstd? ( >=app-arch/zstd-1.3.7-r1:= )
"
DEPEND="${RDEPEND}"

REQUIRED_USE="test? ( jpeg )" #483132


src_prepare() {
	default

	# tiffcp-thumbnail.sh fails as thumbnail binary doesn't get built anymore since tiff-4.0.7
	sed '/tiffcp-thumbnail\.sh/d' -i test/Makefile.am || die

	eautoreconf
}

src_onfigure() {
	local myeconfargs=(
		--with-docdir="${EPREFIX}"/usr/share/doc/${PF}
		$(use_enable cxx)
		$(use_enable jbig)
		$(use_enable jpeg)
		$(use_enable lzma)
		$(use_enable static-libs static)
		$(use_enable webp)
		$(use_enable zlib)
		$(use_enable zstd)
	)
	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"

	# remove useless subdirs
	sed -i \
	    -e 's/ tools//' \
		-e 's/ contrib//' \
		-e 's/ man//' \
		-e 's/ html//' \
		Makefile || die
}

src_test() {
	emake -C tools
	emake check
}

src_install_all() {
	find "${ED}" -type f -name '*.la' -delete || die
	rm "${ED}"/usr/share/doc/${PF}/{README*,RELEASE-DATE,TODO,VERSION} || die
}
