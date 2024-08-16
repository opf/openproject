{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/8ca77a63599ed951d6a2d244c1d62092776a3fe1.tar.gz") {}
}:
with pkgs;
let
  op-get-test-failures = writeShellScriptBin "op-get-test-failures" ''
    exec ${curl}/bin/curl "$$1" | grep 'rspec \.\/' | cut -f3 -d' ' | paste -s -d ' '
  '';

  gems = bundlerEnv {
    name = "openproject-dev";
    inherit ruby;
    gemdir = ./.;
  };
in
  mkShell {
    nativeBuildInputs = [
      buildPackages.ruby_2_7
      postgresql
      nodejs
      tigervnc
      bundix
      docker-compose
      google-chrome

      gems

      op-get-test-failures
    ];

    CHROME_BINARY = "${google-chrome}/bin/google-chrome";
    OPENPROJECT_TESTING_NO_HEADLESS = "1";
    OPENPROJECT_TESTING_AUTO_DEVTOOLS = "1";
}
