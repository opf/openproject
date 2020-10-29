# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'acts_as_tree/version'

Gem::Specification.new do |s|
  s.name        = 'acts_as_tree'
  s.version     = ActsAsTree::VERSION
  s.authors     = ['Erik Dahlstrand', 'Rails Core', 'Mark Turner', 'Swanand Pagnis', 'Felix Bünemann']
  s.email       = ['erik.dahlstrand@gmail.com', 'mark@amerine.net', 'swanand.pagnis@gmail.com', 'felix.buenemann@gmail.com']
  s.homepage    = 'https://github.com/amerine/acts_as_tree'
  s.summary     = %q{Provides a simple tree behaviour to active_record models.}
  s.description = %q{A gem that adds simple support for organizing ActiveRecord models into parent–children relationships.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.rdoc_options  = ["--charset=UTF-8"]

  s.add_dependency "activerecord", ">= 3.0.0"

  # Dependencies (installed via 'bundle install')...
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "minitest", ">= 4.7.5"
end
