#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'open_project/assets'

# The ng build task must run before assets:environment task.
# Otherwise Sprockets cannot find the files that webpack produces.
Rake::Task['assets:precompile']
  .clear_prerequisites
  .enhance(%w[ assets:compile_environment assets:prepare_op])

namespace :assets do
  # In this task, set prerequisites for the assets:precompile task
  task compile_environment: :prepare_op do
    Rake::Task['assets:environment'].invoke
  end

  desc 'Prepare locales and angular assets'
  task prepare_op: [:angular, :export_locales]

  desc 'Compile assets with webpack'
  task :angular do

    # We skip angular compilation if backend was requested
    # but frontend was not explicitly set
    if ENV['RECOMPILE_RAILS_ASSETS'] == 'true' && ENV['RECOMPILE_ANGULAR_ASSETS'] != 'true'
      warn "RECOMPILE_RAILS_ASSETS was set by installation, but RECOMPILE_ANGULAR_ASSETS is false. " \
           "Skipping angular compilation. Set RECOMPILE_ANGULAR_ASSETS='true' if you need to force it."
      next
    end

    OpenProject::Assets.clear!

    puts "Linking frontend plugins"
    Rake::Task['openproject:plugins:register_frontend'].invoke

    puts "Building angular frontend"
    Dir.chdir Rails.root.join('frontend') do
      sh 'npm run build' do |ok, res|
        raise "Failed to compile angular frontend: #{res.exitstatus}" if !ok
      end
    end

    puts "Writing angular assets manifest"
    OpenProject::Assets.rebuild_manifest!
  end

  desc 'Export frontend locale files'
  task export_locales: ['i18n:js:export']

  task :clobber do
    rm_rf FileList["#{Rails.root}/app/assets/javascripts/bundles/*"]
  end
end
