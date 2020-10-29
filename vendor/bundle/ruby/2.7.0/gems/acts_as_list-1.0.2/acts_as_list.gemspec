# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "acts_as_list/version"

Gem::Specification.new do |s|
  # Description Meta...
  s.name                  = "acts_as_list"
  s.version               = ActiveRecord::Acts::List::VERSION
  s.platform              = Gem::Platform::RUBY
  s.authors               = ["Swanand Pagnis", "Brendon Muir"]
  s.email                 = %w(swanand.pagnis@gmail.com brendon@spikeatschool.co.nz)
  s.homepage              = "http://github.com/brendon/acts_as_list"
  s.summary               = "A gem adding sorting, reordering capabilities to an active_record model, allowing it to act as a list"
  s.description           = 'This "acts_as" extension provides the capabilities for sorting and reordering a number of objects in a list. The class that has this specified needs to have a "position" column defined as an integer on the mapped database table.'
  s.license               = "MIT"
  s.required_ruby_version = ">= 2.4.7"

  if s.respond_to?(:metadata)
    s.metadata['changelog_uri']   = 'https://github.com/brendon/acts_as_list/blob/master/CHANGELOG.md'
    s.metadata['source_code_uri'] = 'https://github.com/brendon/acts_as_list'
    s.metadata['bug_tracker_uri'] = 'https://github.com/brendon/acts_as_list/issues'
  end

  # Load Paths...
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map {|f| File.basename(f)}
  s.require_paths = ["lib"]


  # Dependencies (installed via "bundle install")
  s.add_dependency "activerecord", ">= 4.2"
  s.add_development_dependency "bundler", ">= 1.0.0"
end
