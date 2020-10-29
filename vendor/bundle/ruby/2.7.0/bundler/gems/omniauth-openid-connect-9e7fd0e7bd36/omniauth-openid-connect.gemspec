# -*- encoding: utf-8 -*-
# stub: omniauth-openid-connect 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-openid-connect".freeze
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Bohn".freeze]
  s.date = "2020-10-12"
  s.description = "OpenID Connect Strategy for OmniAuth".freeze
  s.email = ["jjbohn@gmail.com".freeze]
  s.files = [".gitignore".freeze, ".travis.yml".freeze, "Gemfile".freeze, "Guardfile".freeze, "LICENSE.txt".freeze, "README.md".freeze, "Rakefile".freeze, "lib/omniauth/openid_connect.rb".freeze, "lib/omniauth/openid_connect/errors.rb".freeze, "lib/omniauth/openid_connect/version.rb".freeze, "lib/omniauth/strategies/openid_connect.rb".freeze, "lib/omniauth_openid_connect.rb".freeze, "omniauth-openid-connect.gemspec".freeze, "test/fixtures/id_token.txt".freeze, "test/fixtures/jwks.json".freeze, "test/fixtures/test.crt".freeze, "test/lib/omniauth/strategies/openid_connect_test.rb".freeze, "test/strategy_test_case.rb".freeze, "test/test_helper.rb".freeze]
  s.homepage = "https://github.com/jjbohn/omniauth-openid-connect".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "OpenID Connect Strategy for OmniAuth".freeze
  s.test_files = ["test/fixtures/id_token.txt".freeze, "test/fixtures/jwks.json".freeze, "test/fixtures/test.crt".freeze, "test/lib/omniauth/strategies/openid_connect_test.rb".freeze, "test/strategy_test_case.rb".freeze, "test/test_helper.rb".freeze]

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<omniauth>.freeze, ["~> 1.6"])
    s.add_runtime_dependency(%q<openid_connect>.freeze, ["~> 1.1.6"])
    s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.5"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.1"])
    s.add_development_dependency(%q<mocha>.freeze, ["~> 1.2"])
    s.add_development_dependency(%q<guard>.freeze, ["~> 2.14"])
    s.add_development_dependency(%q<guard-minitest>.freeze, ["~> 2.4"])
    s.add_development_dependency(%q<guard-bundler>.freeze, ["~> 2.1"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 11.3"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.12"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.9"])
    s.add_development_dependency(%q<coveralls>.freeze, ["~> 0.8"])
    s.add_development_dependency(%q<faker>.freeze, ["~> 1.6"])
  else
    s.add_dependency(%q<omniauth>.freeze, ["~> 1.6"])
    s.add_dependency(%q<openid_connect>.freeze, ["~> 1.1.6"])
    s.add_dependency(%q<addressable>.freeze, ["~> 2.5"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.5"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.1"])
    s.add_dependency(%q<mocha>.freeze, ["~> 1.2"])
    s.add_dependency(%q<guard>.freeze, ["~> 2.14"])
    s.add_dependency(%q<guard-minitest>.freeze, ["~> 2.4"])
    s.add_dependency(%q<guard-bundler>.freeze, ["~> 2.1"])
    s.add_dependency(%q<rake>.freeze, ["~> 11.3"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.12"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.9"])
    s.add_dependency(%q<coveralls>.freeze, ["~> 0.8"])
    s.add_dependency(%q<faker>.freeze, ["~> 1.6"])
  end
end
