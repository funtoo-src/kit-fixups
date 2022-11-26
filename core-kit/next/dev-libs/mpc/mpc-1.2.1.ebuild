# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit multilib-minimal

DESCRIPTION="A library for multiprecision complex arithmetic with exact rounding"
HOMEPAGE="https://www.multiprecision.org/mpc/"
SRC_URI="mirror://gnu/${PN}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0/3" # libmpc.so.3
KEYWORDS="*"
IUSE="static-libs"

DEPEND=">=dev-libs/gmp-5.0.0:0=[${MULTILIB_USEDEP},static-libs?]
	>=dev-libs/mpfr-4.1.0:0=[${MULTILIB_USEDEP},static-libs?]"
RDEPEND="${DEPEND}"

multilib_src_configure() {
	ECONF_SOURCE=${S} econf $(use_enable static-libs static)
}

multilib_src_install_all() {
	einstalldocs
	find "${D}" -name '*.la' -delete || die
}
