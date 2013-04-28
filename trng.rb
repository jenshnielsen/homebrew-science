require 'formula'

class Trng < Formula
  homepage 'http://numbercrunch.de/trng/'
  url 'http://numbercrunch.de/trng/trng-4.14.tar.gz'
  sha1 '199876323e6d4bfdcd6b8cc9df2dd3c0d7ad3170'

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make install"
  end
end
