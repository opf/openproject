#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

#  Run all core and plugins specs via
#  rake spec_all
#
#  Run plugins specs via
#  rake spec_plugins
#
#  A plugin must register for tests via config variable 'plugins_to_test_paths'
#
#  e.g.
#  class Engine < ::Rails::Engine
#    initializer 'register_path_to_rspec' do |app|
#      app.config.plugins_to_test_paths << self.root
#    end
#  end
#

begin
  require 'rspec/core/rake_task'

  namespace :spec do
    desc 'Run core and plugin specs'
    RSpec::Core::RakeTask.new(all: [:environment, 'assets:prepare_op']) do |t|
      t.pattern = [Rails.root.join('spec').to_s] + Plugins::LoadPathHelper.spec_load_paths
    end

    desc 'Run plugin specs'
    RSpec::Core::RakeTask.new(plugins: [:environment, 'assets:prepare_op']) do |t|
      t.pattern = Plugins::LoadPathHelper.spec_load_paths

      # in case we want to run plugins' specs and there are none
      # we exit with positive message
      if t.pattern.empty?
        puts
        puts '##### There are no specs for OpenProject plugins to be run.'
        puts
        exit(0)
      end
    end
  end
rescue LoadError
end
