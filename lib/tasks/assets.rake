#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "open_project/assets"

# The ng build task must run before assets:environment task.
# Otherwise Sprockets cannot find the files that webpack produces.
Rake::Task["assets:precompile"]
  .clear_prerequisites
  .enhance(%w[assets:compile_environment assets:prepare_op])

namespace :assets do
  # In this task, set prerequisites for the assets:precompile task
  task compile_environment: :prepare_op do
    # Turn the yarn:install task into a noop.
    Rake::Task["yarn:install"]
      .clear

    Rake::Task["assets:environment"].invoke
  end

  desc "Prepare locales and angular assets"
  task prepare_op: %i[export_locales angular]

  desc "Compile assets with webpack"
  task :angular do
    # We skip angular compilation if backend was requested
    # but frontend was not explicitly set
    if ENV["RECOMPILE_RAILS_ASSETS"] == "true" && ENV["RECOMPILE_ANGULAR_ASSETS"] != "true"
      next
    end

    OpenProject::Assets.clear!

    puts "Linking frontend plugins"
    Rake::Task["openproject:plugins:register_frontend"].invoke

    puts "Building angular frontend"
    Dir.chdir Rails.root.join("frontend") do
      cmd =
        if ENV["OPENPROJECT_ANGULAR_BUILD"] == "fast"
          "npm run build:fast"
        else
          "npm run build"
        end

      sh(cmd) do |ok, res|
        raise "Failed to compile angular frontend: #{res.exitstatus}" if !ok
      end
    end

    Rake::Task["assets:rebuild_manifest"].invoke
  end

  desc "Write angular assets manifest"
  task :rebuild_manifest do
    puts "Writing angular assets manifest"
    OpenProject::Assets.rebuild_manifest!
  end

  desc "Export frontend locale files"
  task export_locales: :environment do
    puts "Exporting I18n.js locales"
    time = Benchmark.realtime do
      I18nJS.call(config_file: Rails.root.join("config/i18n.yml"))
    end
    puts "=> Done in #{time.round(2)}s"
  end
end
