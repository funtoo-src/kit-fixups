# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic multilib-minimal multiprocessing

DESCRIPTION="sandbox'd LD_PRELOAD hack"
HOMEPAGE="https://wiki.gentoo.org/wiki/Project:Sandbox"
SRC_URI="https://gitweb.gentoo.org/proj/sandbox.git/snapshot/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE=""

DEPEND="app-arch/xz-utils
	>=app-misc/pax-utils-0.1.19" #265376
RDEPEND=""

has sandbox_death_notice ${EBUILD_DEATH_HOOKS} || EBUILD_DEATH_HOOKS="${EBUILD_DEATH_HOOKS} sandbox_death_notice"

sandbox_death_notice() {
	ewarn "If configure failed with a 'cannot run C compiled programs' error, try this:"
	ewarn "FEATURES='-sandbox -usersandbox' emerge sandbox"
}

src_prepare() {
	default

	# sandbox uses `__asm__ (".symver "...` which does
	# not play well with gcc's LTO: https://gcc.gnu.org/PR48200
	append-flags -fno-lto
	append-ldflags -fno-lto
}

multilib_src_configure() {
	filter-lfs-flags #90228

	ECONF_SOURCE="${S}" econf
}

multilib_src_test() {
	# Default sandbox build will run with --jobs set to # cpus.
	# -j1 to prevent test faiures caused by file descriptor
	# injection GNU make does.
	emake -j1 check TESTSUITEFLAGS="--jobs=$(makeopts_jobs)"
}

multilib_src_install_all() {
	echo 'CONFIG_PROTECT_MASK="/etc/sandbox.d"'> "${T}"/09sandbox
	doenvd "${T}"/09sandbox

	keepdir /var/log/sandbox
	fowners root:portage /var/log/sandbox
	fperms 0770 /var/log/sandbox

	dodoc AUTHORS ChangeLog* NEWS README
}

pkg_postinst() {
	chown root:portage "${EROOT}"/var/log/sandbox
	chmod 0770 "${EROOT}"/var/log/sandbox
}
