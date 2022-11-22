# Distributed under the terms of the GNU General Public License v2

EAPI=7

# Note: if bumping pax-utils because of syscall changes in glibc, please
# revbump glibc and update the dependency in its ebuild for the affected
# versions.
PYTHON_COMPAT=( python3+ )

inherit meson python-single-r1

DESCRIPTION="ELF utils that can check files for security relevant properties"
HOMEPAGE="https://wiki.gentoo.org/index.php?title=Project:Hardened/PaX_Utilities"

SRC_URI="https://dev.gentoo.org/~sam/distfiles/${CATEGORY}/${PN}/${P}.tar.xz
	https://dev.gentoo.org/~vapier/dist/${P}.tar.xz"
KEYWORDS="*"

LICENSE="GPL-2"
SLOT="0"
IUSE="caps +man python seccomp test"

_PYTHON_DEPS="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/pyelftools[${PYTHON_USEDEP}]
	')
"

RDEPEND="caps? ( >=sys-libs/libcap-2.24 )
	python? ( ${_PYTHON_DEPS} )
"
DEPEND="${RDEPEND}"
BDEPEND="
	caps? ( virtual/pkgconfig )
	man? ( app-text/xmlto )

	python? ( ${_PYTHON_DEPS} )
"
REQUIRED_USE="
	python
	test? ( python )
"
RESTRICT="
	!test? ( test )
"

PATCHES=(
	"${FILESDIR}/pax-utils-1.3.5-man-reorder-xmlto-arguments.patch"
)

pkg_setup() {
	if use test || use python; then
		python-single-r1_pkg_setup
	fi
}

src_configure() {
	local emesonargs=(
		"-Dlddtree_implementation=$(usex python python sh)"
		$(meson_feature caps use_libcap)
		$(meson_feature man build_manpages)
		$(meson_use seccomp use_seccomp)
		$(meson_use test tests)

		# fuzzing is currently broken
		-Duse_fuzzing=false
	)
	meson_src_configure
}

src_install() {
	meson_src_install

	use python && python_fix_shebang "${ED}"/usr/bin/lddtree
}
