{
  stdenv,
  lib,
  fetchFromGitLab,
  gitUpdater,
  nixosTests,
  cmake,
  cmake-extras,
  dbus,
  dbus-test-runner,
  gtest,
  libnotify,
  pkg-config,
  polkit,
  properties-cpp,
  python3,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri-polkit-agent";
  version = "0.3";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/core/lomiri-polkit-agent";
    tag = finalAttrs.version;
    hash = "sha256-3x2gwKhRDXE6tuwM7pXIwsWg/8pQrKLJ1zds8Ljtk+I=";
  };

  strictDeps = true;

  postPatch = ''
    # GTest needs C++17
    # Remove when https://gitlab.com/ubports/development/core/lomiri-polkit-agent/-/merge_requests/15 merged & in release
    substituteInPlace CMakeLists.txt \
      --replace-fail 'std=c++14' 'std=c++17'
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    cmake-extras
    libnotify
    polkit
    properties-cpp
  ];

  nativeCheckInputs = [
    dbus
    (python3.withPackages (ps: with ps; [ python-dbusmock ]))
  ];

  checkInputs = [
    dbus-test-runner
    gtest
  ];

  doCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;

  # Parallelism breaks dbus during tests
  enableParallelChecking = false;

  passthru = {
    # Involves a test to check polkit agent functionality.
    # The pop-up dialogue times out after awhile, and OCR can't find it in time.
    # Please check the screenshots after running that test, to verify that the pop-up actually happened!
    tests.vm = nixosTests.lomiri.desktop-appinteractions;
    updateScript = gitUpdater { };
  };

  meta = {
    description = "Policy kit agent for the Lomiri desktop";
    homepage = "https://gitlab.com/ubports/development/core/lomiri-polkit-agent";
    changelog = "https://gitlab.com/ubports/development/core/lomiri-polkit-agent/-/blob/${
      if (!builtins.isNull finalAttrs.src.tag) then finalAttrs.src.tag else finalAttrs.src.rev
    }/ChangeLog";
    license = lib.licenses.gpl3Only;
    teams = [ lib.teams.lomiri ];
    platforms = lib.platforms.linux;
  };
})
