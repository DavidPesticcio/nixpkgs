{ lib, stdenv, fetchurl, patchelf, glibc }:

stdenv.mkDerivation rec {
  pname   = "fj";
  version = "0.7.0";
  __structuredAttrs = true;

  src = fetchurl {
    url = "https://rasterhub.com/rasterstate/fj/releases/download/v0.7.0/fj-v0.7.0-linux-x86_64.tar.gz";
    hash = "sha256-kwOxrXqXVEywf8ydU/33F9v8taxpyXYe8jrsCWHoBa8=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cd $out/bin
    tar -xf $src --strip-components=1
    patchelf --set-interpreter ${glibc}/lib64/ld-linux-x86-64.so.2 fj
    chmod +x fj
  '';

  nativeBuildInputs = [ patchelf ];

  meta = with lib; {
    description = "A native CLI for Forgejo and Gitea-compatible forges";
    homepage    = "https://rasterhub.com/rasterstate/fj";
    license     = licenses.mit;
    platforms   = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ];
    maintainers = [ ];
    mainProgram = "fj";
  };
}
