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

class RemoveTimelinesNamespace < ActiveRecord::Migration
  def self.up

    # rename all tables.
    # this changes everything. again.

    rename_table('timelines_alternate_dates',                'alternate_dates')
    rename_table('timelines_available_project_statuses',     'available_project_statuses')
    rename_table('timelines_colors',                         'planning_element_type_colors')
    rename_table('timelines_default_planning_element_types', 'default_planning_element_types')
    rename_table('timelines_enabled_planning_element_types', 'enabled_planning_element_types')
    rename_table('timelines_planning_element_types',         'planning_element_types')
    rename_table('timelines_planning_elements',              'planning_elements')
    rename_table('timelines_project_associations',           'project_associations')
    rename_table('timelines_project_types',                  'project_types')
    rename_table('timelines_reportings',                     'reportings')
    rename_table('timelines_scenarios',                      'scenarios')
    rename_table('timelines_timelines',                      'timelines')

    # rename some foreign key columns.

    rename_column('projects', 'timelines_project_type_id', 'project_type_id')
    rename_column('projects', 'timelines_responsible_id',  'responsible_id')

  end

  def down

    # rename all tables

    rename_table('alternate_dates',                'timelines_alternate_dates')
    rename_table('available_project_statuses',     'timelines_available_project_statuses')
    rename_table('default_planning_element_types', 'timelines_default_planning_element_types')
    rename_table('enabled_planning_element_types', 'timelines_enabled_planning_element_types')
    rename_table('planning_element_type_colors',   'timelines_colors')
    rename_table('planning_element_types',         'timelines_planning_element_types')
    rename_table('planning_elements',              'timelines_planning_elements')
    rename_table('project_associations',           'timelines_project_associations')
    rename_table('project_types',                  'timelines_project_types')
    rename_table('reportings',                     'timelines_reportings')
    rename_table('scenarios',                      'timelines_scenarios')
    rename_table('timelines',                      'timelines_timelines')

    # rename some foreign key columns.

    rename_column('projects', 'project_type_id', 'timelines_project_type_id')
    rename_column('projects', 'responsible_id',  'timelines_responsible_id')
  end
end
