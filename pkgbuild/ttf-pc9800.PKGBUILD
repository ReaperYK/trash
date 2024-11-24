# Maintainer: baraclese at gmail dot com
pkgname=ttf-pc9800
pkgver=1.0.0
pkgrel=1
pkgdesc='NEC PC-9800 series built-in bitmap font (TTF version)'
url='https://retro-type.com/PC98/font/'
arch=('any')
license=('custom')
source=(
	'https://retro-type.com/PC98/font/pc-9800.ttf'
    'https://retro-type.com/PC98/font/pc-9800-bold.ttf'
)
#source=(
# 'https://web.archive.org/web/20220215031454/https://retro-type.com/PC98/font/pc-9800.ttf
# 'https://web.archive.org/web/20220215031449/https://retro-type.com/PC98/font/pc-9800-bold.ttf'
# )

sha256sums=(
	'ef8a08868d2d279aac1f3d646899c574775b1b8d692de54f1de08722eded7333'
    '716689ade9476f07c521864b56cefa7238252487444da29f2cd092c49eff1408'
)

package() {
	cd "${srcdir}"
	install -d "${pkgdir}/usr/share/fonts/TTF"
	install -m 644 *.ttf "${pkgdir}/usr/share/fonts/TTF"
}
