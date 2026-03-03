pkgname=x3dctl
pkgver=1.0.0
pkgrel=1
pkgdesc="Deterministic workload policy controller for AMD X3D processors"
arch=('x86_64')
url="https://github.com/GrandBIRDLizard/X3Dctl"
license=('MIT')
depends=('sudo')
makedepends=('gcc' 'make')
backup=('etc/x3dctl.conf')
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/GrandBIRDLizard/X3Dctl/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('REPLACE_WITH_HASH')

build() {
  cd "${srcdir}/X3Dctl-${pkgver}"
  make
}

package() {
  cd "${srcdir}/X3Dctl-${pkgver}"
  make DESTDIR="${pkgdir}" PREFIX=/usr install

  install -Dm644 LICENSE "${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
}
