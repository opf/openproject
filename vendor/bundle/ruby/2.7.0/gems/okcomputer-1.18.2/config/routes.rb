OkComputer::Engine.routes.draw do
  root to: "ok_computer#show", via: [:get, :options], check: "default"
  match "/all" => "ok_computer#index", via: [:get, :options], as: :okcomputer_checks
  match "/:check" => "ok_computer#show", via: [:get, :options], as: :okcomputer_check
end
