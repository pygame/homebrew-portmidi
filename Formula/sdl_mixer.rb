class SdlMixer < Formula
  desc "Sample multi-channel audio mixer library"
  homepage "https://www.libsdl.org/projects/SDL_mixer/"
  url "https://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.12.tar.gz"
  sha256 "1644308279a975799049e4826af2cfc787cad2abb11aa14562e402521f86992a"
  revision 3

  depends_on "pkg-config" => :build
  depends_on "pygame/portmidi/libmikmod"
  depends_on "libogg"
  depends_on "libvorbis"
  depends_on "pygame/portmidi/sdl"
  depends_on "flac" => :optional
  depends_on "pygame/portmidi/fluid-synth" => :optional
  depends_on "pygame/portmidi/smpeg" => :optional

  patch do
    url "https://git.archlinux.org/svntogit/packages.git/plain/trunk/double-free-crash.patch?h=packages/sdl_mixer"
    sha256 "b707f5c8d1229d1612cc8a9f4e976f0a3b19ea40d7bd1d5bc1cbd5c9f8bca56d"
  end

  def install
    inreplace "SDL_mixer.pc.in", "@prefix@", HOMEBREW_PREFIX

    args = %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
      --enable-music-ogg
      --disable-music-ogg-shared
      --disable-music-mod-shared
    ]

    args << "--disable-music-fluidsynth-shared" if build.with? "fluid-synth"
    args << "--disable-music-flac-shared" if build.with? "flac"
    args << "--disable-music-mp3-shared" if build.with? "smpeg"

    system "./configure", *args
    system "make", "install"
  end
end

