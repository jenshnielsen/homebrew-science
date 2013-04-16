require 'formula'

class Vmtk < Formula
  homepage 'http://www.vmtk.org'
  url 'http://sourceforge.net/projects/vmtk/files/vmtk/1.0/vmtk-1.0.1.tar.gz'
  sha1 'ae2da67e60a288512158e9361106aa3c789c14b9'

  head 'git://github.com/vmtk/vmtk.git'

  depends_on 'cmake' => :build
  #depends_on 'insighttoolkit3'
  depends_on 'vtk'
  def install
    args = std_cmake_args + %W[
      -DUSE_SYSTEM_ITK=ON
      -DUSE_SYSTEM_VTK=ON
    "]
    args << ".."
    args << '-DCMAKE_PREFIX_PATH=' + Formula.factory("insighttoolkit3")
    mkdir 'vmtk-build' do
      system "cmake", *args
      system "make"
      system "make install"
    end
  end
end
