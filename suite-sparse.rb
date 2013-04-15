require 'formula'

class SuiteSparse < Formula
  homepage 'http://www.cise.ufl.edu/research/sparse/SuiteSparse'
  url 'http://www.cise.ufl.edu/research/sparse/SuiteSparse/SuiteSparse-4.1.0.tar.gz'
  sha1 '93a0ae741b399d0dbecd43235d2f8977cdd9bc47'

  option "without-tbb", "Do not link with tbb (Threading Building Block)"
  option "with-metis", "Compile in metis 4.x libraries"
  option "with-openblas", "Use openblas instead of Apple's Accelerate.framework"

  depends_on "tbb" unless build.include? "without-tbb"
  # Metis is optional for now because of
  # cholmod_metis.c:164:21: error: use of undeclared identifier 'idxtype'
  depends_on "metis4" if build.include? "with-metis"
  depends_on "openblas" if build.include? "with-openblas"

  def install
    # SuiteSparse doesn't like to build in parallel
    ENV.j1

    # Switch to the Mac base config, per SuiteSparse README.txt
    system "mv SuiteSparse_config/SuiteSparse_config.mk SuiteSparse_config/SuiteSparse_config_orig.mk"
    system "mv SuiteSparse_config/SuiteSparse_config_Mac.mk SuiteSparse_config/SuiteSparse_config.mk"
    
    inreplace "SuiteSparse_config/SuiteSparse_config.mk" do |s|
      if build.include? 'with-openblas'
        s.change_make_var! "BLAS", "-lopenblas"
        s.change_make_var! "LAPACK", "$(BLAS)"
      end

      unless build.include? "without-tbb"
        s.change_make_var! "SPQR_CONFIG", "-DHAVE_TBB"
        s.change_make_var! "TBB", "-ltbb"
      end

      if build.include? "with-metis"
        s.remove_make_var! "METIS_PATH"
        s.change_make_var! "METIS", Formula.factory("metis4").lib + "libmetis.a"
      else
        # Use -DNCAMD to work around apparent bug in -I setup, matching 4.0.2 behavior
        s.change_make_var! "CHOLMOD_CONFIG", "-DNCAMD"
      end

      s.change_make_var! "INSTALL_LIB", lib
      s.change_make_var! "INSTALL_INCLUDE", include
    end

    system "make library"

    lib.mkpath
    include.mkpath
    system "make install"
  end
end
