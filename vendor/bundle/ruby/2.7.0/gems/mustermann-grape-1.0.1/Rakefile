# frozen_string_literal: true

require 'rubygems'
require 'bundler'
Bundler.setup :default, :test, :development

Bundler::GemHelper.install_tasks

task(default: :rspec)
task(:rspec) { ruby '-S rspec' }
