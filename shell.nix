{ pkgs ? import <nixpkgs> {} }:
with pkgs;
let 
  op-get-routes = writeShellScriptBin "op-get-routes" ''
    ${docker-compose}/bin/docker-compose exec backend rails runner 'API::Root.routes.each do |api|
      method = api.request_method.ljust(10)
      path = api.path
      puts "#{method} #{path}"
    end'
  '';
  op-get-test-failures = writeShellScriptBin "op-get-test-failures" ''
    PASTED="$(${wl-clipboard}/bin/wl-paste)"
    URL="$${1:-$PASTED}"

    echo "LOADING FROM $URL"
    exec ${curl}/bin/curl "$URL" | grep 'rspec \.\/' | cut -f3 -d' ' | paste -s -d ' '
  '';
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

