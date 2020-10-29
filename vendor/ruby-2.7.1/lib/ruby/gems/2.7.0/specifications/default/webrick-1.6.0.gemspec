# -*- encoding: utf-8 -*-
# stub: webrick 1.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "webrick".freeze
  s.version = "1.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://bugs.ruby-lang.org/projects/ruby-trunk/issues", "homepage_uri" => "https://www.ruby-lang.org", "source_code_uri" => "https://git.ruby-lang.org/ruby.git/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["TAKAHASHI Masayoshi".freeze, "GOTOU YUUZOU".freeze, "Eric Wong".freeze]
  s.date = "2020-04-16"
  s.description = "WEBrick is an HTTP server toolkit that can be configured as an HTTPS server, a proxy server, and a virtual-host server.".freeze
  s.email = [nil, nil, "normal@ruby-lang.org".freeze]
  s.files = ["webrick.rb".freeze, "webrick/accesslog.rb".freeze, "webrick/cgi.rb".freeze, "webrick/compat.rb".freeze, "webrick/config.rb".freeze, "webrick/cookie.rb".freeze, "webrick/htmlutils.rb".freeze, "webrick/httpauth.rb".freeze, "webrick/httpauth/authenticator.rb".freeze, "webrick/httpauth/basicauth.rb".freeze, "webrick/httpauth/digestauth.rb".freeze, "webrick/httpauth/htdigest.rb".freeze, "webrick/httpauth/htgroup.rb".freeze, "webrick/httpauth/htpasswd.rb".freeze, "webrick/httpauth/userdb.rb".freeze, "webrick/httpproxy.rb".freeze, "webrick/httprequest.rb".freeze, "webrick/httpresponse.rb".freeze, "webrick/https.rb".freeze, "webrick/httpserver.rb".freeze, "webrick/httpservlet.rb".freeze, "webrick/httpservlet/abstract.rb".freeze, "webrick/httpservlet/cgi_runner.rb".freeze, "webrick/httpservlet/cgihandler.rb".freeze, "webrick/httpservlet/erbhandler.rb".freeze, "webrick/httpservlet/filehandler.rb".freeze, "webrick/httpservlet/prochandler.rb".freeze, "webrick/httpstatus.rb".freeze, "webrick/httputils.rb".freeze, "webrick/httpversion.rb".freeze, "webrick/log.rb".freeze, "webrick/server.rb".freeze, "webrick/ssl.rb".freeze, "webrick/utils.rb".freeze, "webrick/version.rb".freeze]
  s.homepage = "https://www.ruby-lang.org".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "HTTP server toolkit".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
