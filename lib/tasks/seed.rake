# frozen_string_literal: true

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

namespace :db do
  namespace :seed do
    desc "Run a single seeder"
    task :only, [:seeder_class_name] => [:environment] do |_task, args|
      seeder_class_name = args.fetch(:seeder_class_name, nil)
      if seeder_class_name.nil?
        raise "Specify a seeder class name 'rake db:seed:only[Some::ClassName]'"
      end

      RootSeeder.new.seed_data! do |root_seeder|
        seeder_class = seeder_class_name.constantize
        if seeder_class.ancestors.exclude?(Seeder)
          raise ArgumentError, "#{seeder_class_name} is not a seeder"
        end

        puts "Running #{seeder_class} seeder"
        seeder = seeder_class.new(root_seeder.seed_data)
        seeder.seed!
      rescue NameError
        raise ArgumentError, "No seeder with class name #{seeder_class_name}"
      end
    end
  end
end
