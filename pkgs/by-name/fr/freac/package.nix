{
  lib,
  stdenv,
  fetchFromGitHub,
  pkgs,

  boca,
  smooth,
  systemd,

  curlFull,
  gnome-icon-theme,
  openssl,
  tree,

#  exhale # Missing from nixpkgs as of 2024/12/18
  faac,
  faad2,
  fdk_aac,
  ffmpeg,
  flac, # Broken reference via {$flac}
  lame, # Broken reference via {$lame}
  libcdio,
  libcdio-paranoia,
#  libcdrip, # Missing from nixpkgs as of 2024/12/18
  libogg,
  libopus,
  libsamplerate, # Broken reference via {$libsamplerate}
  libsndfile, # Broken reference via {$libsndfile}
  libvorbis,
  mac,
  mp4v2,
  mpg123,
#  musepack, # Missing from nixpkgs as of 2024/12/18 ?
  rnnoise,
  rubberband,
  speex,
  wavpack,
}:

# NOTE: For more details on building fre:ac for Linux & MacOS visit the following URLs:
# https://github.com/enzo1982/freac/blob/master/.github/workflows/tools/build-appimage
# https://github.com/enzo1982/freac/blob/master/.github/workflows/tools/build-macos
# https://github.com/enzo1982/freac/blob/master/tools/build-codecs


stdenv.mkDerivation rec {
  pname = "freac";
  version = "1.1.7";

  src = fetchFromGitHub {
    owner = "enzo1982";
    repo = "freac";
    rev = "v${version}";
    sha256 = "sha256-bHoRxxhSM7ipRkiBG7hEa1Iw8Z3tOHQ/atngC/3X1a4=";
  };

  nativeBuildInputs = [
    boca
    smooth
    systemd

    curlFull
    gnome-icon-theme
    openssl
    tree
  ] ++ (with pkgs; [
#    exhale # 1.2.0 - https://gitlab.com/ecodis/exhale
    faac # 1.30 - https://github.com/knik0/faac
    faad2 # 2.10.0 - https://github.com/knik0/faad2
    fdk_aac # 2.0.3 - https://sourceforge.net/projects/opencore-amr/files/fdk-aac
    ffmpeg # 7.1 - https://ffmpeg.org/releases
    flac # 1.4.3 - https://ftp.osuosl.org/pub/xiph/releases/flac
    lame # 3.100 - https://sourceforge.net/projects/lame/files/lame
    libcdio # 2.1.0 - https://ftp.gnu.org/gnu/libcdio/
    libcdio-paranoia # 10.2+2.0.1 - https://ftp.gnu.org/gnu/libcdio
#    libcdrip # 2.4a - http://cdrip.org/releases/
    libogg # 1.3.5 - https://ftp.osuosl.org/pub/xiph/releases/ogg
    libopus # 1.5.2 - https://ftp.osuosl.org/pub/xiph/releases/opus
    libsamplerate # 0.2.2 - https://github.com/libsndfile/libsamplerate
    libsndfile # 1.2.2 - https://github.com/libsndfile/libsndfile
    libvorbis # 1.3.7 - https://ftp.osuosl.org/pub/xiph/releases/vorbis
    mac # 10.82 - https://freac.org/patches
    mp4v2 # 2.1.3 - https://github.com/enzo1982/mp4v2
    mpg123 # 32.9 - https://mpg123.org/download
#    musepack # 4.75 - https://files.musepack.net/source
    rnnoise # 9acc1e5 - https://codeload.github.com/xiph/rnnoise
    rubberband # 1.8.2 - https://breakfastquay.com/files/releases
    speex # 1.2.1 - https://ftp.osuosl.org/pub/xiph/releases/speex
    wavpack # 5.7.0 -https://www.wavpack.com/
  ]);

  makeFlags = [
    "prefix=$(out)"
  ];

  # Note: Non-standard references to files by fre:ac requires following the structure as described in;
  #       https://github.com/enzo1982/freac/blob/master/.github/workflows/tools/build-appimage
  postBuild = ''
    codecs=$out/bin/codecs
    cmdline=$codecs/cmdline

    # TODO: Get upstream packages for the following files fixed so we don't need this nasty hack.
    libFLAC=$(find /nix/store/ -name libFLAC.so)
    libmp3lame=$(find /nix/store/ -name libmp3lame.so)
    libsamplerate=$(find /nix/store/ -name libsamplerate.so)
    libsndfile=$(find /nix/store/ -name libsndfile.so)
    libcurl=$(find /nix/store/ -name libcurl.so.4)
    libcurl=$(find /nix/store/ -name libcurl.so)

    mkdir -p $out/boca
    mkdir -p $cmdline
    mkdir -p $out/icons/gnome/32x32/status
    mkdir -p $out/usr/share/applications
    mkdir -p $out/usr/share/metainfo

    ##########
    # Install codecs
    install -Dm 444 ${faad2}/lib/libfaad.so               $codecs/faad.so
    install -Dm 444 ${fdk_aac}/lib/libfdk-aac.so          $codecs/fdk-aac.so

    # Uncomment the line below, and remove line below that when upstream is fixed.
    # install -Dm 444 ${flac}/lib/libFLAC.so                $codecs/FLAC.so
    install -Dm 444 $libFLAC                              $codecs/FLAC.so

    # Uncomment the line below, and remove line below that when upstream is fixed.
    # install -Dm 444 ${lame}/lib/libmp3lame.so             $codecs/mp3lame.so
    install -Dm 444 $libmp3lame                           $codecs/mp3lame.so

    install -Dm 444 ${mac}/lib/libMAC.so                  $codecs/MAC.so
    install -Dm 444 ${mp4v2}/lib/libmp4v2.so              $codecs/mp4v2.so
    install -Dm 444 ${mpg123}/lib/libmpg123.so            $codecs/mpg123.so
    install -Dm 444 ${libogg}/lib/libogg.so               $codecs/ogg.so
    install -Dm 444 ${libopus}/lib/libopus.so             $codecs/opus.so
    install -Dm 444 ${rnnoise}/lib/librnnoise.so          $codecs/rnnoise.so
    install -Dm 444 ${rubberband}/lib/librubberband.so    $codecs/rubberband.so

    # Uncomment the line below, and remove line below that when upstream is fixed.
    # install -Dm 444 ${libsamplerate}/lib/libsamplerate.so $codecs/samplerate.so
    install -Dm 444 $libsamplerate                        $codecs/samplerate.so

    # Uncomment the line below, and remove line below that when upstream is fixed.
    # install -Dm 444 ${libsndfile}/lib/libsndfile.so       $codecs/sndfile.so
    install -Dm 444 $libsndfile                           $codecs/sndfile.so

    install -Dm 444 ${speex}/lib/libspeex.so          $codecs/speex.so
    install -Dm 444 ${libvorbis}/lib/libvorbisenc.so  $codecs/vorbisenc.so
    install -Dm 444 ${libvorbis}/lib/libvorbis.so     $codecs/vorbis.so

    install -Dm 0755 ${ffmpeg}/bin/ffmpeg   $cmdline/ffmpeg
    # install -Dm 0755 $\{}/bin/mpcdec   $cmdline/mpcdec # Musepack decode
    # install -Dm 0755 $\{}/bin/mpcenc   $cmdline/mpcenc # Musepack encode
    install -Dm 0755 ${wavpack}/bin/wavpack  $cmdline/wavpack
    install -Dm 0755 ${wavpack}/bin/wvunpack $cmdline/wvunpack

    ##########
    # Copy icons
    cp ${gnome-icon-theme}/share/icons/gnome/32x32/status/dialog-error.png        $out/icons/gnome/32x32/status
    cp ${gnome-icon-theme}/share/icons/gnome/32x32/status/dialog-information.png  $out/icons/gnome/32x32/status
    cp ${gnome-icon-theme}/share/icons/gnome/32x32/status/dialog-question.png     $out/icons/gnome/32x32/status
    cp ${gnome-icon-theme}/share/icons/gnome/32x32/status/dialog-warning.png      $out/icons/gnome/32x32/status

    ##########
    # Copy fre:ac
    cp COPYING Readme* $out

    # cp -r /lib/freac/*            $out/boca/
    # cp -r /share/freac/lang       $out
    cp -r icons      $out
    cp -r manual     $out

    install -Dm 0755 ${smooth}/bin/smooth-translator $out/translator

    cp metadata/org.freac.freac.desktop                        $out/usr/share/applications/
    cp metadata/org.freac.freac.appdata.xml                    $out/usr/share/metainfo/
    ln -s $out/usr/share/applications/org.freac.freac.desktop  $out/org.freac.freac.desktop
    cp icons/freac.png                                         $out/org.freac.freac.png

    ##########
    # Copy other dependencies
    cp ${libcdio}/lib/libcdio.so.19                   $out
    cp ${libcdio-paranoia}/lib/libcdio_cdda.so.2      $out
    cp ${libcdio-paranoia}/lib/libcdio_paranoia.so.2  $out

    # Uncomment the line below, and remove line below that when upstream is fixed.
    # cp -v ${curlFull}/lib/libcurl.so.4                   $out
    # cp -v $libcurl                                        $out
    echo $libcurl

    # cp -v -P ${openssl}/lib/libcrypto.so*  $out
    # cp -v -P ${openssl}/lib/libssl.so*     $out

    ls -l $out
    tree $out
  '';

  meta = with lib; {
    changelog = "https://github.com/enzo1982/freac/releases/tag/v${version}";
    description = "Audio converter and CD ripper with support for various popular formats and encoders";
    homepage = "https://www.freac.org/";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ shamilton ];
    platforms = platforms.linux;
  };
}
