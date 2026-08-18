pkgname=x3dctl
pkgver=1.4.1
pkgrel=1
pkgdesc="Lightweight utility for AMD X3D mode switching, IRQ steering, and per-process policy"
arch=('x86_64')
url="https://github.com/GrandBIRDLizard/X3Dctl"
license=('MIT')
depends=('sudo' 'libcap')
makedepends=('make' 'gcc')
backup=('etc/x3dctl.conf')
install=x3dctl.install
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/GrandBIRDLizard/X3Dctl/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('REPLACE_WITH_REAL_HASH')

build() {
  cd "${srcdir}/X3Dctl-${pkgver}"
  make
}

package() {
  cd "${srcdir}/X3Dctl-${pkgver}"

  make DESTDIR="${pkgdir}" PREFIX=/usr install

  install -Dm644 LICENSE \
      "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
