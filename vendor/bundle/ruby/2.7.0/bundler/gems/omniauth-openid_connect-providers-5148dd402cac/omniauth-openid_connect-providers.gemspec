# -*- encoding: utf-8 -*-
# stub: omniauth-openid_connect-providers 0.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-openid_connect-providers".freeze
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Finn GmbH".freeze]
  s.date = "2020-10-12"
  s.email = ["info@finn.de".freeze]
  s.files = [".gitignore".freeze, ".rspec".freeze, ".travis.yml".freeze, "Gemfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "lib/omniauth/openid_connect/azure.rb".freeze, "lib/omniauth/openid_connect/google.rb".freeze, "lib/omniauth/openid_connect/heroku.rb".freeze, "lib/omniauth/openid_connect/provider.rb".freeze, "lib/omniauth/openid_connect/providers.rb".freeze, "lib/omniauth/openid_connect/providers/version.rb".freeze, "omniauth-openid_connect-providers.gemspec".freeze, "spec/provider_spec.rb".freeze, "spec/providers_spec.rb".freeze]
  s.homepage = "https://github.com/finnlabs/omniauth-openid_connect-providers".freeze
  s.licenses = ["GPLv3".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Offers a means to configure OmniAuth OpenIDConnect providers comfortably.".freeze
  s.test_files = ["spec/provider_spec.rb".freeze, "spec/providers_spec.rb".freeze]

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<omniauth-openid-connect>.freeze, [">= 0.2.1"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 1.5"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 3.1.0"])
    s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  else
    s.add_dependency(%q<omniauth-openid-connect>.freeze, [">= 0.2.1"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.5"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 3.1.0"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
  end
end
