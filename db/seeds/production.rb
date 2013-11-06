#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# add seeds specific for the production-environment here

require_relative '../migrate/migration_utils/timelines'

standard_type = Type.find_by_is_standard(true)

# Adds the standard type to all existing projects
#
# As this seed might be executed on an existing database, there might be projects
# that do not have the default type yet.

projects_without_standard_type = Project.where("NOT EXISTS (SELECT * from projects_types WHERE projects.id = projects_types.project_id AND projects_types.type_id = #{standard_type.id})")
                                        .all

projects_without_standard_type.each do |project|
  project.types << standard_type
end

# Fixes work packages that do not have a type yet. They receive the standard type.
#
# This can happen when an existing database, having timelines planning elements,
# gets migrated. During the migration, the existing planning elements are converted
# to work_packages. Because the existance of a standard type cannot be guaranteed
# during the migration, such work packages receive a type_id of 0.
#
# Because all work packages that do not a type yet should always have had one
# (from todays standpoint) the assignment is done covertedly.

[WorkPackage, Journal::WorkPackageJournal].each do |klass|
  klass.update_all({ :type_id => standard_type.id }, { :type_id => [0, nil] })
end

class MigrateTimelinesOptions < ActiveRecord::Migration
  include Migration::Utils

  def initialize(standard_type)
    @standard_type = standard_type
  end

  def migrate
    say_with_time_silently "Set 'none' type id in timelines options" do
      update_column_values('timelines',
                           ['options'],
                           update_options(add_none_type_id),
                          nil)
    end
  end

  def add_none_type_id
    Proc.new do |timelines_opts|
      add_none_type_id_to_options timelines_opts
    end
  end

  PE_TYPE_KEY = 'planning_element_types'

  def add_none_type_id_to_options(options)
    pe_types = []
    pe_types = options[PE_TYPE_KEY] if options.has_key? PE_TYPE_KEY

    pe_types.map! { |t| (t == 0) ? @standard_type.id : t }

    options[PE_TYPE_KEY] = pe_types

    options
  end
end

timelines_migrator = MigrateTimelinesOptions.new(standard_type)

timelines_migrator.migrate
