source "https://rubygems.org"

gemspec

active_model_opts =
  case version = ENV['ACTIVE_MODEL_VERSION'] || "master"
  when 'master' then { github: 'rails/rails' }
  when 'default' then '~> 3'
  else "~> #{version}"
  end

gem 'activemodel', active_model_opts

platforms :rbx do
  gem 'rubysl', '~> 2.0'
end
