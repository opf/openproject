# For OpenProject development on Nix

This directory contains files that ease development on nix-enabled systems. Just run `nix-shell ./nix` in the root project directory.

The setup was tested on docker-enabled systems, however nothing should stop you from using this without docker.

This is still a work in progress, feel free to improve the development experience on Nix.

## Updating gemset.nix

Run `bundix --gemset=./nix/gemset.nix` to update the gemset file from the Gemlock file.

## Autoloading

If you have `lorri` and `direnv` installed, you can autoload the shell by adding a `.envrc` to the root directory with
the following contents: 

```
eval "$(lorri direnv --shell-file ./nix/shell.nix)"
```
