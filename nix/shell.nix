{ pkgs ? import <nixpkgs> {} }:
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
    # nativeBuildInputs is usually what you want -- tools you need to run
    nativeBuildInputs = [
      buildPackages.ruby_2_7
      postgresql
      nodejs
      tightvnc
      bundix
      docker-compose
      google-chrome

      op-get-routes
      op-get-test-failures
    ];

    CHROME_BINARY = "${google-chrome}/bin/google-chrome";
    OPENPROJECT_TESTING_NO_HEADLESS = "1";
    OPENPROJECT_TESTING_AUTO_DEVTOOLS = "1";
}

