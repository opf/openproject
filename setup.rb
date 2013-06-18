#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

$output_prefix = "==> "
$parsed_options = nil

def abort_installation!
  puts $output_prefix + "Something went wrong :("
  puts $output_prefix + "Installation aborted."
  return false
end

def check_ruby_version
  puts $output_prefix + "Checking Ruby Version"
  ruby_version = `ruby --version`

  version_check = ruby_version.scan("ruby 1.8.7")
  patchlevel_check = ruby_version.scan("patchlevel 371")

  if version_check.empty?
    puts $output_prefix + "It seems you are not using the recommended ruby version."
    puts $output_prefix + "Please make sure you have installed 'ruby 1.8.7 (2012-10-12 patchlevel 371)'"
  elsif patchlevel_check.empty?
    puts $output_prefix + "It seems you are not running the recommended patch level."
    puts $output_prefix + "To avoid unexpected problems we would recommend to install 'ruby 1.8.7 (2012-10-12 patchlevel 371)'"
  else
    puts $output_prefix + "Found"
  end
end

def check_bundler
  puts $output_prefix + "Checking Bundler"
  unless system "bundle --version > /dev/null"
    puts $output_prefix + "It seems bundler is not installed. Please install bundler before running setup.rb."
    puts $output_prefix + "For bundler and more information visit: http://gembundler.com/"
    return false
  else
    puts $output_prefix + "Found"
    return true
  end
end

def check_git
  puts $output_prefix + "Checking git"
  unless system "git --version > /dev/null"
    puts $output_prefix + "It seems git is not installed. Please install git before running setup.rb."
    return false
  else
    puts $output_prefix + "Found"
    return true
  end
end

def check_for_db_yaml
  unless File.exists?(ROOT + '/config/database.yml')
    puts $output_prefix + "Please configure your database before installing OpenProject."
    puts $output_prefix + "Create and configure config/database.yml to do that."
    return false
  else
    return true
  end
end

def concatenate_options(parsed_options, option)
  return parsed_options[option] ? parsed_options[option].inject(""){|result,a| result + a + " "} : nil
end

def parse_argv(option)
  return concatenate_options($parsed_options, option) if $parsed_options

  params_hash = {}

  name = nil
  ARGV.each do |param|
    if param[0,2] == "--"
      name = param
      params_hash[name] = []
    else
      params_hash[name] << param
    end
  end

  $parsed_options = params_hash
  return concatenate_options($parsed_options, option)
end

def checkout_default_plugins
  exec_dir = Dir.pwd + "/vendor"
  plugin_install_dir = Dir.pwd + "/vendor/plugins/"
  default_plugin_file = File.join(Dir.pwd, "plugin_config.yml")

  config = YAML.load_file(default_plugin_file)

  forced = parse_argv("--force")
  config.each_pair do |key, mod_config|

    Dir.chdir exec_dir
    plugin_path = File.join(exec_dir, key)


    if forced and File.exists?(plugin_path)
      puts $output_prefix + "Deleting #{plugin_path}.."
      FileUtils.rm_rf(plugin_path)
    end

    if mod_config.keys.include?("repository") and not File.exists?(plugin_path)
      system "git clone #{mod_config["repository"]} #{key}"
    end

    Dir.chdir plugin_path

    if mod_config.keys.include?("branch")
      unless `git branch`.split.include?(mod_config['branch'])
        system "git branch #{mod_config["branch"]} origin/#{mod_config["branch"]}"
      end

      if `git branch | grep '*'`.delete('*').chomp.strip != mod_config["branch"]
        system "git checkout #{mod_config["branch"]}"
        system "git merge origin/#{mod_config["branch"]}"
      else
        system "git merge origin/#{mod_config["branch"]}"
      end
    end

    if mod_config.keys.include?("commit")
      system "git reset #{mod_config['commit']}"
    end

    Dir.chdir exec_dir
  end
end

def setup_openproject
  puts $output_prefix + "Installing Gems via Bundler"
  unless system("bundle install --without rmagick " + parse_argv("--without").to_s)
    return false
  end


  if check_for_db_yaml
    puts $output_prefix + "Creating database"

    if parse_argv("--force")
      puts $output_prefix + "Drop all databases"
      return false unless system("rake db:drop:all")
    end

    return false unless system("rake db:create:all") and migrate_core
  else
    return false
  end

  puts $output_prefix + "Generate Session Store"
  system("rake generate_session_store")
end

def migrate_core
  puts $output_prefix + "Migrate Core"
  return system("rake db:migrate")
end

def install
  puts $output_prefix + 'Installing OpenProject...'


  check_ruby_version
  if not check_bundler or not check_git # check for dependencies
    return abort_installation!
  end

  unless checkout_default_plugins # clone plugins
    return abort_installation!
  end

  Dir.chdir ROOT

  return abort_installation! unless setup_openproject # Start installation
  puts $output_prefix + "Installation Succeeded"
end

ROOT = Dir.pwd
# TODO: make a Rails3 setup script
puts "Setup-script currently disabled. This script should be adaptet to rails 3."
abort_installation
install
