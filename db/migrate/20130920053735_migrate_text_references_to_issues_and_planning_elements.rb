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

require 'yaml'

require_relative 'migration_utils/utils'

class MigrateTextReferencesToIssuesAndPlanningElements < ActiveRecord::Migration
  include Migration::Utils

  COLUMNS_PER_TABLE = {
    'boards' => ['description'],
    'changesets' => ['comments'],
    'journals' => ['notes'],
    'messages' => ['content'],
    'news' => ['summary', 'description'],
    'projects' => ['description'],
    'wiki_contents' => ['text'],
    'work_packages' => ['description'],

    'changeset_journals' => ['comments'],
    'message_journals' => ['content'],
    'news_journals' => ['summary', 'description'],
    'wiki_content_journals' => ['text'],
    'work_package_journals' => ['description']
  }

  def up
    COLUMNS_PER_TABLE.each_pair do |table, columns|
      say_with_time_silently "Update text references for table #{table}" do
        update_column_values(table,
                             columns,
                             update_text_references(columns, planning_element_to_work_package_id_map),
                             update_filter(columns))
      end
    end
  end

  def down
    COLUMNS_PER_TABLE.each_pair do |table, columns|
      say_with_time_silently "Restore text references for table #{table}" do
        update_column_values(table,
                             columns,
                             restore_text_references(columns, work_package_to_planning_element_id_map),
                             restore_filter(columns))
      end
    end
  end

  private

  def update_filter(columns)
    filter columns, ['issue', 'planning_element', '*']
  end

  def restore_filter(columns)
    filter columns, ['work_package', '#']
  end

  def filter(columns, terms)
    column_filters = []

    columns.each do |column|
      filters = terms.map {|term| "#{column} LIKE '%#{term}%'"}

      column_filters << "(#{filters.join(' OR ')})"
    end

    column_filters.join(' OR ')
  end

  def update_text_references(columns, id_map)
    Proc.new do |row|
      columns.each do |column|
        row[column] = update_work_package_macros row[column], id_map, MACRO_REGEX, /\*/, '#'
        row[column] = update_issue_planning_element_links row[column], id_map
      end

      row
    end
  end

  def restore_text_references(columns, id_map)
    Proc.new do |row|
      columns.each do |column|
        row[column] = update_work_package_macros row[column], id_map, RESTORE_MACRO_REGEX, /#/, '*'
        row[column] = restore_issue_planning_element_links row[column], id_map
      end

      row
    end
  end

  MACRO_REGEX = /(?<dots>\*{1,3})(?<id>\d+)/
  RESTORE_MACRO_REGEX = /(?<dots>\#{1,3})(?<id>\d+)/

  def update_work_package_macros(text, id_map, regex, macro_regex, replacement)
    unless text.nil?
      text.gsub!(regex) do |match|
        if id_map.has_key? $~[:id].to_s
          new_id = id_map[$~[:id].to_s][:new_id]
          hash_macro = $~[:dots].gsub(macro_regex, replacement)

          "#{hash_macro}#{new_id}"
        end
      end
    end

    text
  end

  WORK_PACKAGE_LINK_REGEX = /(?<host>http:\/\/(\w|:)*)(\/timelines)?(\/projects\/(\w|-)*)?\/(issues|planning_elements)\/(?<id>\w*)/
  REL_WORK_PACKAGE_LINK_REGEX = /(?<title>"(\w|\s)*"):(\/timelines)?(\/projects\/(\w|-)*)?\/(issues|planning_elements)\/(?<id>\w*)/

  def update_issue_planning_element_links(text, id_map)
    unless text.nil?
      text.gsub!(WORK_PACKAGE_LINK_REGEX) {|_| update_issue_planning_element_link_match $~, id_map}
      text.gsub!(REL_WORK_PACKAGE_LINK_REGEX) {|_| update_issue_planning_element_link_match $~, id_map}
    end

    text
  end

  RESTORE_WORK_PACKAGE_LINK_REGEX = /(?<host>http:\/\/(\w|:)*)\/work_packages\/(?<id>\w*)/
  RESTORE_REL_WORK_PACKAGE_LINK_REGEX = /(?<title>"(\w|\s)*"):\/work_packages\/(?<id>\w*)/

  def restore_issue_planning_element_links(text, id_map)
    text.gsub!(RESTORE_WORK_PACKAGE_LINK_REGEX) {|_| restore_issue_planning_element_link_match $~, id_map}
    text.gsub!(RESTORE_REL_WORK_PACKAGE_LINK_REGEX) {|_| restore_issue_planning_element_link_match $~, id_map}
  end

  def update_issue_planning_element_link_match(match, id_map)
    "#{link_prefix match}/work_packages/#{element_id match, id_map}"
  end

  def restore_issue_planning_element_link_match(match, id_map)
    if id_map.has_key? match[:id].to_s
      project_id = id_map[match[:id].to_s][:project_id]
      "#{link_prefix match}/timelines/projects/#{project_id}/planning_elements/#{element_id match, id_map}"
    else
      "#{link_prefix match}/issues/#{element_id match, id_map}"
    end
  end

  def link_prefix(match)
    match.names.include?('host') ? match[:host] : "#{match[:title]}:"
  end

  def element_id(match, id_map)
    id = match[:id].to_s
    id = id_map[id][:new_id] if id_map.has_key? id
    id
  end

  def planning_element_to_work_package_id_map
    create_planning_element_id_map 'id', 'new_id'
  end

  def work_package_to_planning_element_id_map
    create_planning_element_id_map 'new_id', 'id'
  end

  def create_planning_element_id_map(key, value)
    old_and_new_ids = select_all <<-SQL
      SELECT id, new_id, project_id
      FROM legacy_planning_elements
    SQL

    old_and_new_ids.each_with_object({}) {|row, hash| hash[row[key]] = { new_id: row[value], project_id: row['project_id']}}
  end
end
