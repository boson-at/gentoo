# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python2_7 python3_{5,6,7,8} pypy{,3} )

inherit distutils-r1

DESCRIPTION="Simple powerful testing with Python"
HOMEPAGE="http://pytest.org/"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
RESTRICT="!test? ( test )"

# When bumping, please check setup.py for the proper py version
PY_VER="1.5.0"

# pathlib2 has been added to stdlib before py3.6, but pytest needs __fspath__
# support, which only came in py3.6.
RDEPEND="
	>=dev-python/atomicwrites-1.0[${PYTHON_USEDEP}]
	>=dev-python/attrs-17.4.0[${PYTHON_USEDEP}]
	>=dev-python/more-itertools-4.0.0[${PYTHON_USEDEP}]
	$(python_gen_cond_dep 'dev-python/importlib_metadata[${PYTHON_USEDEP}]' \
		-2 python3_{5,6,7} pypy3)
	$(python_gen_cond_dep 'dev-python/pathlib2[${PYTHON_USEDEP}]' -2 python3_5)
	>=dev-python/pluggy-0.12[${PYTHON_USEDEP}]
	<dev-python/pluggy-1
	>=dev-python/py-${PY_VER}[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
	dev-python/wcwidth[${PYTHON_USEDEP}]
	virtual/python-funcsigs[${PYTHON_USEDEP}]"

# Temporary hack to avoid py38 keywording hell.  Please remove when
# the test deps all have py38.  Also pytest's test pass with py38,
# so you need to hack them all in locally before bumping and test.
TEST_USEDEP=$(python_gen_usedep python2_7 python3_{5,6,7} pypy{,3})
# flake cause a number of tests to fail
DEPEND="
	dev-python/setuptools[${PYTHON_USEDEP}]
	test? (
		${RDEPEND}
		dev-python/argcomplete[${TEST_USEDEP}]
		>=dev-python/hypothesis-3.56[${TEST_USEDEP}]
		dev-python/nose[${TEST_USEDEP}]
		$(python_gen_cond_dep 'dev-python/mock[${PYTHON_USEDEP}]' -2)
		dev-python/pexpect[${TEST_USEDEP}]
		dev-python/pytest-xdist[${TEST_USEDEP}]
		dev-python/requests[${TEST_USEDEP}]
		!!dev-python/flaky
	)"

PATCHES=(
	"${FILESDIR}/${PN}-4.5.0-strip-setuptools_scm.patch"
)

python_prepare_all() {
	grep -qF "py>=${PY_VER}" setup.py || die "Incorrect dev-python/py dependency"

	# Something in the ebuild environment causes this to hang/error.
	# https://bugs.gentoo.org/598442
	rm testing/test_pdb.py || die

	distutils-r1_python_prepare_all
}

python_test() {
	if [[ ${EPYTHON} == python3.8 ]]; then
		if [[ ${PV} != 4.6.6 ]]; then
			eerror "Please disable py38 hacks and test locally, then update this."
			die "Python 3.8 support untested for ${PV}"
		fi
		einfo "Skipping testing on ${EPYTHON} due to unkeyworded deps"
		return
	fi

	# In v4.1.1, pytest started being picky about its own verbosity options.
	# running pytest on itself with -vv made 3 tests fail. This is why we don't
	# have it below.
	"${EPYTHON}" "${BUILD_DIR}"/lib/pytest.py --lsof -rfsxX \
		|| die "tests failed with ${EPYTHON}"
}