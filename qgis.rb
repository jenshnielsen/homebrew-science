require 'formula'

class PyQtImportable < Requirement
  fatal true
  satisfy { quiet_system 'python', '-c', 'from PyQt4 import QtCore' }

  def message
    <<-EOS.undent
      Python could not import the PyQt4 module. This will cause the QGIS build to fail.
      The most common reason for this failure is that the PYTHONPATH needs to be adjusted.
      The pyqt caveats explain this adjustment and may be reviewed using:

          brew info pyqt
    EOS
  end
end

class Qgis < Formula
  homepage 'http://www.qgis.org'
  url 'http://qgis.org/downloads/qgis-1.8.0.tar.bz2'
  sha1 '99c0d716acbe0dd70ad0774242d01e9251c5a130'

  head 'https://github.com/qgis/Quantum-GIS.git', :branch => 'master'

  depends_on 'cmake' => :build
  depends_on :python
  depends_on PyQtImportable

  depends_on 'gsl'
  depends_on 'pyqt'
  depends_on 'qwt'
  depends_on 'expat'
  depends_on 'gdal'
  depends_on 'proj'
  depends_on 'spatialindex'
  depends_on 'bison'
  depends_on 'grass' => :optional
  depends_on 'gettext' if build.with? 'grass'
  depends_on 'postgis' => :optional

  def patches
    # make honoring -DPYTHON_LIBRARY more solid. This is taken from a Qgis pull request. The present version
    # looks for the existense of a file -DPYTHON_LIBRARY not what the variable points to. This breaks 
    # linking agains homebrew python.
    'https://github.com/mbernasocchi/Quantum-GIS/commit/51fdbcbb0d842183498f0052a704d94222ffbac2.patch'
  end

  def install
    # Set bundling level back to 0 (the default in all versions prior to 1.8.0)
    # so that no time and energy is wasted copying the Qt frameworks into QGIS.
    # At the moment Qgis uses the old -DPYTHON_INCLUDE_PATH not -DPYTHON_INCLUDE_DIR
    # this may change in the future so we set both.
    args = std_cmake_args.concat %W[
      -DQWT_INCLUDE_DIR=#{Formula.factory('qwt').opt_prefix}/lib/qwt.framework/Headers/
      -DQWT_LIBRARY=#{Formula.factory('qwt').opt_prefix}/lib/qwt.framework/qwt
      -DBISON_EXECUTABLE=#{Formula.factory('bison').opt_prefix}/bin/bison
      -DENABLE_TESTS=NO
      -DQGIS_MACAPP_BUNDLE=0
      -DQGIS_MACAPP_DEV_PREFIX='#{prefix}/Frameworks'
      -DQGIS_MACAPP_INSTALL_DEV=YES
      -DPYTHON_INCLUDE_DIR='#{python.incdir}'
      -DPYTHON_INCLUDE_PATH='#{python.incdir}'
      -DPYTHON_LIBRARY='#{python.libdir}/lib#{python.xy}.dylib'
    ]

    args << "-DGRASS_PREFIX='#{Formula.factory('grass').opt_prefix}'" if build.with? 'grass'

    # So that `libintl.h` can be found
    ENV.append 'CXXFLAGS', "-I'#{Formula.factory('gettext').opt_prefix}/include'" if build.with? 'grass'

    # Avoid ld: framework not found QtSql (https://github.com/Homebrew/homebrew-science/issues/23)
    ENV.append 'CXXFLAGS', "-F#{Formula.factory('qt').opt_prefix}/lib"

    Dir.mkdir 'build'
    python do
      Dir.chdir 'build' do
        system 'cmake', '..', *args
        system 'make install'
      end

      py_lib = lib/"#{python.xy}/site-packages"
      qgis_modules = prefix + 'QGIS.app/Contents/Resources/python/qgis'
      py_lib.mkpath
      ln_s qgis_modules, py_lib + 'qgis'

      # Create script to launch QGIS app
      (bin + 'qgis').write <<-EOS.undent
        #!/bin/sh
        # Ensure Python modules can be found when QGIS is running.
        env PATH='#{HOMEBREW_PREFIX}/bin':$PATH PYTHONPATH='#{HOMEBREW_PREFIX}/lib/#{python.xy}/site-packages':$PYTHONPATH\\
          open #{prefix}/QGIS.app
      EOS
    end
  end

  def caveats
    s = <<-EOS.undent
      QGIS has been built as an application bundle. To make it easily available, a
      wrapper script has been written that launches the app with environment
      variables set so that Python modules will be functional:

        qgis

      You may also symlink QGIS.app into ~/Applications:
        brew linkapps
        mkdir -p #{ENV['HOME']}/.MacOSX
        defaults write #{ENV['HOME']}/.MacOSX/environment.plist PYTHONPATH -string "#{HOMEBREW_PREFIX}/lib/#{python.xy}/site-packages"

      You will need to log out and log in again to make environment.plist effective.

    EOS
    s += python.standard_caveats if python
    s
  end
end
