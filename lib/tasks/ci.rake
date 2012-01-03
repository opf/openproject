#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

desc "Run the Continous Integration tests for Redmine"
task :ci do
  # RAILS_ENV and ENV[] can diverge so force them both to test
  ENV['RAILS_ENV'] = 'test'
  RAILS_ENV = 'test'
  Rake::Task["ci:setup"].invoke
  Rake::Task["ci:build"].invoke
  Rake::Task["ci:teardown"].invoke
end

# Tasks can be hooked into by redefining them in a plugin
namespace :ci do
  desc "Setup Redmine for a new build."
  task :setup do
    Rake::Task["ci:dump_environment"].invoke
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:migrate:plugins"].invoke
    Rake::Task["db:schema:dump"].invoke
    Rake::Task["test:scm:update"].invoke
  end

  desc "Build Redmine"
  task :build do
    Rake::Task["test"].invoke
  end

  # Use this to cleanup after building or run post-build analysis.
  desc "Finish the build"
  task :teardown do
  end

  desc "Dump the environment information to a BUILD_ENVIRONMENT ENV variable for debugging"
  task :dump_environment do

    ENV['BUILD_ENVIRONMENT'] = ['ruby -v', 'gem -v', 'gem list'].collect do |command|
      result = `#{command}`
      "$ #{command}\n#{result}"
    end.join("\n")

  end
end

