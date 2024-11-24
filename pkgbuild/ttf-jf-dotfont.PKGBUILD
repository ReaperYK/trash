# Maintainer: baraclese at gmail dot com
pkgname=ttf-jf-dotfont
pkgver=1.00.20150527
pkgrel=1
pkgdesc='A complete package of JF Japanese bitmap fonts. (jiskan, shinonome, mplus, ..etc)'
url='http://jikasei.me/font'
arch=('any')
license=('custom')
source=('https://ftp.iij.ad.jp/pub/osdn.jp/users/8/8542/jfdotfont-20150527.zip')
#source=('https://web.archive.org/web/20240210065405/https://ftp.iij.ad.jp/pub/osdn.jp/users/8/8542/jfdotfont-20150527.zip'
sha256sums=('8e574faaaa7e27294aec66464aaf427447b2f0ccec8fe00c50e69bbf509f14b1')

package() {
	cd "${srcdir}"
	install -d "${pkgdir}/usr/share/fonts/TTF"
	install -m 644 *.ttf "${pkgdir}/usr/share/fonts/TTF"
}
