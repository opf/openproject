# frozen_string_literal: true

require 'rake'
require 'rspec/core/rake_task'
require 'yard'
require 'rubygems/package_task'
require 'rubocop/rake_task'

task default: %i[spec rubocop]

desc 'Run all rspec files'
RSpec::Core::RakeTask.new('spec') do |c|
  c.rspec_opts = '-t ~unresolved'
end

YARD::Rake::YardocTask.new do |t|
  t.options = ['--output-dir', 'doc/html']
end
task docs: :yard

desc "Generate the 'Prawn by Example' manual"
task :manual do
  puts 'Building manual...'
  require File.expand_path(File.join(__dir__, %w[manual contents]))
  prawn_manual_document.render_file('manual.pdf')
  puts 'The Prawn manual is available at manual.pdf. Happy Prawning!'
end

spec = Gem::Specification.load 'prawn.gemspec'
Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc 'Run a console with Prawn loaded'
task :console do
  require 'irb'
  require 'irb/completion'
  require_relative 'lib/prawn'
  Prawn.debug = true

  ARGV.clear
  IRB.start
end

RuboCop::RakeTask.new

task :checksum do
  require 'digest/sha2'
  built_gem_path = "prawn-#{Prawn::VERSION}.gem"
  checksum = Digest::SHA512.new.hexdigest(File.read(built_gem_path))
  checksum_path = "checksums/#{built_gem_path}.sha512"
  File.write(checksum_path, checksum)
end
