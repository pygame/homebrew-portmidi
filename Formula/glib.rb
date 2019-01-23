class Glib < Formula
  desc "Core application library for C"
  homepage "https://developer.gnome.org/glib/"
  url "https://download.gnome.org/sources/glib/2.58/glib-2.58.2.tar.xz"
  sha256 "c7b24ed6536f1a10fc9bce7994e55c427b727602e78342821f1f07fb48753d4b"

  bottle do
    rebuild 1
    root_url "https://github.com/pygame/homebrew-portmidi/releases/download/bottles0"
    sha256 "0ea5bd0dbfec49ac5404279359f3d4aa8f6444b9ded0ad8f12457fd82d35d78b" => :el_capitan
  end

  # autoconf, automake and libtool can be removed when
  # bug 780271 is fixed and gio.patch is modified accordingly
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  #depends_on "pygame/portmidi/gtk-doc" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "pygame/portmidi/gettext"
  depends_on "pygame/portmidi/libffi"
  depends_on "pygame/portmidi/pcre"

  # https://bugzilla.gnome.org/show_bug.cgi?id=673135 Resolved as wontfix,
  # but needed to fix an assumption about the location of the d-bus machine
  # id file.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/59e4d32/glib/hardcoded-paths.diff"
    sha256 "a4cb96b5861672ec0750cb30ecebe1d417d38052cac12fbb8a77dbf04a886fcb"
  end

  # Revert some bad macOS specific commits
  # https://bugzilla.gnome.org/show_bug.cgi?id=780271
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/5857984/glib/revert-appinfo-contenttype.patch"
    sha256 "88bfc2a69aaeda07c5f057d11e106a97837ff319f8be1f553b8537f3c136f48c"
  end

  def install
    inreplace %w[gio/gdbusprivate.c gio/xdgmime/xdgmime.c glib/gutils.c],
      "@@HOMEBREW_PREFIX@@", HOMEBREW_PREFIX

    # Disable dtrace; see https://trac.macports.org/ticket/30413
    args = %W[
      --disable-gtk-doc
      --disable-maintainer-mode
      --disable-dependency-tracking
      --disable-silent-rules
      --disable-dtrace
      --disable-libelf
      --enable-static
      --prefix=#{prefix}
      --localstatedir=#{var}
      --with-gio-module-dir=#{HOMEBREW_PREFIX}/lib/gio/modules
    ]

    # next two lines can be removed when bug 780271 is fixed and gio.patch
    # is modified accordingly
    ENV["NOCONFIGURE"] = "1"
    system "./autogen.sh"

    system "./configure", *args

    # disable creating directory for GIO_MODULE_DIR, we will do
    # this manually in post_install
    inreplace "gio/Makefile",
              "$(mkinstalldirs) $(DESTDIR)$(GIO_MODULE_DIR)",
              ""

    # ensure giomoduledir contains prefix, as this pkgconfig variable will be
    # used by glib-networking and glib-openssl to determine where to install
    # their modules
    inreplace "gio-2.0.pc",
              "giomoduledir=#{HOMEBREW_PREFIX}/lib/gio/modules",
              "giomoduledir=${prefix}/lib/gio/modules"

    system "make"
    system "make", "install"

    # `pkg-config --libs glib-2.0` includes -lintl, and gettext itself does not
    # have a pkgconfig file, so we add gettext lib and include paths here.
    gettext = Formula["pygame/portmidi/gettext"].opt_prefix
    inreplace lib+"pkgconfig/glib-2.0.pc" do |s|
      s.gsub! "Libs: -L${libdir} -lglib-2.0 -lintl",
              "Libs: -L${libdir} -lglib-2.0 -L#{gettext}/lib -lintl"
      s.gsub! "Cflags: -I${includedir}/glib-2.0 -I${libdir}/glib-2.0/include",
              "Cflags: -I${includedir}/glib-2.0 -I${libdir}/glib-2.0/include -I#{gettext}/include"
    end
  end

  def post_install
    (HOMEBREW_PREFIX/"lib/gio/modules").mkpath
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <string.h>
      #include <glib.h>

      int main(void)
      {
          gchar *result_1, *result_2;
          char *str = "string";

          result_1 = g_convert(str, strlen(str), "ASCII", "UTF-8", NULL, NULL, NULL);
          result_2 = g_convert(result_1, strlen(result_1), "UTF-8", "ASCII", NULL, NULL, NULL);

          return (strcmp(str, result_2) == 0) ? 0 : 1;
      }
    EOS
    system ENV.cc, "-o", "test", "test.c", "-I#{include}/glib-2.0",
                   "-I#{lib}/glib-2.0/include", "-L#{lib}", "-lglib-2.0"
    system "./test"
  end
end
