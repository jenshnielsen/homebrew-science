require 'formula'

class Insighttoolkit3 < Formula
  homepage 'http://www.itk.org'
  url 'http://sourceforge.net/projects/itk/files/itk/3.20/InsightToolkit-3.20.1.tar.gz'
  sha1 'e35f2971244870adcd0b479ee74660a216408e97'

  head 'git://itk.org/ITK.git'

  keg_only "Conflicts with Insighttoolkit (4.x)."
  option 'examples', 'Compile and install various examples'
  option 'with-opencv-bridge', 'Include OpenCV bridge'

  depends_on 'cmake' => :build

  def install
    args = std_cmake_args + %W[
      -DBUILD_TESTING=OFF
      -DBUILD_SHARED_LIBS=ON
    ]
    args << ".."
    args << '-DBUILD_EXAMPLES=' + ((build.include? 'examples') ? 'ON' : 'OFF')
    args << '-DModule_ITKVideoBridgeOpenCV=' + ((build.include? 'with-opencv-bridge') ? 'ON' : 'OFF')

    mkdir 'itk-build' do
      system "cmake", *args
      system "make install"
    end
  end
end
