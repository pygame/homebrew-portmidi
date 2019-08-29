class Sdl2 < Formula
  desc "Low-level access to audio, keyboard, mouse, joystick, and graphics"
  homepage "https://www.libsdl.org/"

  stable do
    url "https://libsdl.org/release/SDL2-2.0.10.tar.gz"
    sha256 "b4656c13a1f0d0023ae2f4a9cf08ec92fffb464e0f24238337784159b8b91d57"
  end

  bottle do
    cellar :any
  end

  head do
    url "https://hg.libsdl.org/SDL", :using => :hg

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  # Fix 10.11 compilation.
  patch :p0 do
    url "https://gist.githubusercontent.com/illume/ac2eb4daa1bd805255d5355806acf822/raw/7e3c83f760fe5bf61a9f6bcc196ed9be6f6e22da/sdl2-mac-10-11.patch"
    sha256 "25f534e35f92244f006e4d2e5740bc65f502136ffa5ebe8427963434bd46f590"
  end

  def install
    # we have to do this because most build scripts assume that all sdl modules
    # are installed to the same prefix. Consequently SDL stuff cannot be
    # keg-only but I doubt that will be needed.
    inreplace %w[sdl2.pc.in sdl2-config.in], "@prefix@", HOMEBREW_PREFIX

    system "./autogen.sh" if build.head? || build.devel?

    args = %W[--prefix=#{prefix} --without-x]
    system "./configure", *args
    system "make", "install"
  end

  test do
    system bin/"sdl2-config", "--version"
  end
end

