{
  stdenv,
  lib,
  pkgs,
  fetchurl,
  bash,
  buildEnv,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  getopt,
  git,
  tree,
  gnupg,
  openssl,
  which,
  openssh,
  procps,
  qrencode,
  makeWrapper,
  pass,

  xclip ? null,
  xdotool ? null,
  dmenu ? null,
  x11Support ? !stdenv.hostPlatform.isDarwin,
  dmenuSupport ? (x11Support || waylandSupport),
  waylandSupport ? false,
  wl-clipboard ? null,
  ydotool ? null,
  dmenu-wayland ? null,

  # For backwards-compatibility
  tombPluginSupport ? false,
}:

assert x11Support -> xclip != null;
assert waylandSupport -> wl-clipboard != null;

assert dmenuSupport -> x11Support || waylandSupport;
assert dmenuSupport && x11Support -> dmenu != null && xdotool != null;
assert dmenuSupport && waylandSupport -> dmenu-wayland != null && ydotool != null;

let
  passExtensions = import ./extensions { inherit pkgs; };

  env =
    extensions:
    let
      selected = [
        pass
      ]
      ++ extensions passExtensions
      ++ lib.optional tombPluginSupport passExtensions.tomb;
    in
    buildEnv {
      name = "pass-env";
      paths = selected;
      nativeBuildInputs = [ makeWrapper ];
      buildInputs = lib.concatMap (x: x.buildInputs) selected;

      postBuild = ''
        files=$(find $out/bin/ -type f -exec readlink -f {} \;)
        if [ -L $out/bin ]; then
          rm $out/bin
          mkdir $out/bin
        fi

        for i in $files; do
          if ! [ "$(readlink -f "$out/bin/$(basename $i)")" = "$i" ]; then
            ln -sf $i $out/bin/$(basename $i)
          fi
        done

        wrapProgram $out/bin/pass \
          --set SYSTEM_EXTENSION_DIR "$out/lib/password-store/extensions"
      '';
      meta.mainProgram = "pass";
    };
in

stdenv.mkDerivation rec {
  version = "1.7.4";
  pname = "password-store";

  src = fetchurl {
    url = "https://git.zx2c4.com/password-store/snapshot/${pname}-${version}.tar.xz";
    sha256 = "1h4k6w7g8pr169p5w9n6mkdhxl3pw51zphx7www6pvgjb7vgmafg";
  };

  patches = [
    ./set-correct-program-name-for-sleep.patch
    ./extension-dir.patch
  ]
  ++ lib.optional stdenv.hostPlatform.isDarwin ./no-darwin-getopt.patch;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ bash ];

  installFlags = [
    "PREFIX=$(out)"
    "WITH_ALLCOMP=yes"
  ];

  postInstall = lib.optionalString dmenuSupport ''
    cp "contrib/dmenu/passmenu" "$out/bin/"
  '';

  wrapperPath = lib.makeBinPath (
    [
      coreutils
      findutils
      getopt
      git
      gnugrep
      gnupg
      gnused
      tree
      which
      openssh
      procps
      qrencode
    ]
    ++ lib.optional stdenv.hostPlatform.isDarwin openssl
    ++ lib.optional x11Support xclip
    ++ lib.optional waylandSupport wl-clipboard
    ++ lib.optionals (waylandSupport && dmenuSupport) [
      ydotool
      dmenu-wayland
    ]
    ++ lib.optionals (x11Support && dmenuSupport) [
      xdotool
      dmenu
    ]
  );

  postFixup = ''
    # Fix program name in --help
    substituteInPlace $out/bin/pass \
      --replace 'PROGRAM="''${0##*/}"' "PROGRAM=pass"

    # Ensure all dependencies are in PATH
    wrapProgram $out/bin/pass \
      --prefix PATH : "${wrapperPath}"
  ''
  + lib.optionalString dmenuSupport ''
    # We just wrap passmenu with the same PATH as pass. It doesn't
    # need all the tools in there but it doesn't hurt either.
    wrapProgram $out/bin/passmenu \
      --prefix PATH : "$out/bin:${wrapperPath}"
  '';

  # Turn "check" into "installcheck", since we want to test our pass,
  # not the one before the fixup.
  postPatch = ''
    patchShebangs tests

    substituteInPlace src/password-store.sh \
      --replace "@out@" "$out"

    # the turning
    sed -i -e 's@^PASS=.*''$@PASS=$out/bin/pass@' \
           -e 's@^GPGS=.*''$@GPG=${gnupg}/bin/gpg2@' \
           -e '/which gpg/ d' \
      tests/setup.sh
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    # 'pass edit' uses hdid, which is not available from the sandbox.
    rm -f tests/t0200-edit-tests.sh
    rm -f tests/t0010-generate-tests.sh
    rm -f tests/t0020-show-tests.sh
    rm -f tests/t0050-mv-tests.sh
    rm -f tests/t0100-insert-tests.sh
    rm -f tests/t0300-reencryption.sh
    rm -f tests/t0400-grep.sh
  '';

  doCheck = false;

  doInstallCheck = true;
  nativeInstallCheckInputs = [ git ];
  installCheckTarget = "test";

  passthru = {
    extensions = passExtensions;
    withExtensions = env;
  };

  meta = with lib; {
    description = "Stores, retrieves, generates, and synchronizes passwords securely";
    homepage = "https://www.passwordstore.org/";
    license = licenses.gpl2Plus;
    mainProgram = "pass";
    maintainers = with maintainers; [
      lovek323
      fpletz
      tadfisher
      globin
      ma27
      ryan4yin
    ];
    platforms = platforms.unix;

    longDescription = ''
      pass is a very simple password store that keeps passwords inside gpg2
      encrypted files inside a simple directory tree residing at
      ~/.password-store. The pass utility provides a series of commands for
      manipulating the password store, allowing the user to add, remove, edit,
      synchronize, generate, and manipulate passwords.
    '';
  };
}
