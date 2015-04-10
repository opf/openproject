#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require_relative 'utils'

module Migration
  module Utils
    def update_text_references(table, columns, update_journal)
      id_update_map = planning_element_to_work_package_id_map

      update_column_values_and_journals(table,
                                        columns,
                                        process_text_update(columns, id_update_map),
                                        update_journal,
                                        update_filter(columns))
    end

    def restore_text_references(table, columns, update_journal)
      id_restore_map = work_package_to_planning_element_id_map

      update_column_values_and_journals(table,
                                        columns,
                                        process_text_restore(columns, id_restore_map),
                                        update_journal,
                                        restore_filter(columns))
    end

    private

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

      old_and_new_ids.each_with_object({}) do |row, hash|
        current_id = row[key].to_s
        new_id = row[value].to_s
        project_id = row['project_id'].to_s

        hash[current_id] = { new_id: new_id, project_id: project_id }
      end
    end

    def process_text_update(columns, id_map)
      Proc.new do |row|
        updated = false

        columns.each do |column|
          original = row[column]

          row[column] = update_work_package_macros row[column], id_map, NOTES_MACRO_REGEX, /\*/, '#'
          row[column] = update_work_package_macros row[column], id_map, MACRO_REGEX, /\*/, '#'
          row[column] = update_issue_planning_element_links row[column], id_map

          updated ||= original != row[column]
        end

        UpdateResult.new(row, updated)
      end
    end

    def process_text_restore(columns, id_map)
      Proc.new do |row|
        updated = false

        columns.each do |column|
          original = row[column]

          row[column] = update_work_package_macros row[column], id_map, RESTORE_NOTES_MACRO_REGEX, /#/, '*'
          row[column] = update_work_package_macros row[column], id_map, RESTORE_MACRO_REGEX, /#/, '*'
          row[column] = restore_issue_planning_element_links row[column], id_map

          updated ||= original != row[column]
        end

        UpdateResult.new(row, updated)
      end
    end

    NOTES_MACRO_REGEX = /(?<prefix>\_Updated automatically by changing values within child planning element )((?<dots>\*{1,3})(?<id>\d+))(?<postfix>\_)/
    MACRO_REGEX = /(?:\W|^|\A)((?<dots>\*{1,3})(?<id>\d+))(?:\W|$|\z)/
    RESTORE_NOTES_MACRO_REGEX = /(?<prefix>\_Updated automatically by changing values within child planning element )((?<dots>\#{1,3})(?<id>\d+))(?<postfix>\_)/
    RESTORE_MACRO_REGEX = /(?:\W|^|\A)((?<dots>\#{1,3})(?<id>\d+))(?:\W|$|\z)/

    def update_work_package_macros(text, id_map, regex, macro_regex, new_macro)
      unless text.nil?
        text = parse_non_pre_blocks(text) do |block|
          block.gsub!(regex) do |match|
            if id_map.has_key? $~[:id].to_s
              prefix = $~.names.include?('prefix') ? $~[:prefix] : ' '
              postfix = $~.names.include?('postfix') ? $~[:postfix] : ' '
              new_id = id_map[$~[:id].to_s][:new_id]
              hash_macro = $~[:dots].gsub(macro_regex, new_macro)

              "#{prefix}#{hash_macro}#{new_id}#{postfix}"
            else
              match
            end
          end
        end
      end

      text
    end

    def update_issue_planning_element_links(text, id_map)
      unless text.nil?
        text = parse_non_pre_blocks(text) do |block|
          block.gsub!(work_package_link_regex) { |_| update_issue_planning_element_link_match $~, id_map }
          block.gsub!(rel_work_package_link_regex) { |_| update_issue_planning_element_link_match $~, id_map }
        end
      end

      text
    end

    def work_package_link_regex
      @work_package_link_regex ||= Regexp.new "(?<host>http(s)?:\/\/#{Regexp.escape(host_name)})(\/timelines)?(\/projects\/(\\w|-)*)?\/(issues|planning_elements)\/(?<id>\\w*)"
    end

    def rel_work_package_link_regex
      @rel_work_package_link_regex ||= Regexp.new "(?<title>\"(\\w|\\s)*\"):#{Regexp.escape(host_postfix)}(\/timelines)?(\/projects\/(\\w|-)*)?\/(issues|planning_elements)\/(?<id>\\w*)"
    end

    def restore_issue_planning_element_links(text, id_map)
      unless text.nil?
        text = parse_non_pre_blocks(text) do |_block|
          text.gsub!(restore_work_package_link_regex) { |_| restore_issue_planning_element_link_match $~, id_map }
          text.gsub!(restore_rel_work_package_link_regex) { |_| restore_issue_planning_element_link_match $~, id_map }
        end
      end

      text
    end

    def restore_work_package_link_regex
      @restore_work_package_link_regex ||= Regexp.new "(?<host>http(s)?:\/\/#{Regexp.escape(host_name)})\/work_packages\/(?<id>\\w*)"
    end

    def restore_rel_work_package_link_regex
      @restore_rel_work_package_link_regex ||= Regexp.new "(?<title>\"(\\w|\\s)*\"):#{Regexp.escape(host_postfix)}\/work_packages\/(?<id>\\w*)"
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
      match.names.include?('host') ? match[:host] : "#{match[:title]}:#{host_postfix}"
    end

    def element_id(match, id_map)
      id = match[:id].to_s
      id = id_map[id][:new_id] if id_map.has_key? id
      id
    end

    # taken from app/helper/application_helper.rb
    def parse_non_pre_blocks(text)
      s = StringScanner.new(text)
      tags = []
      parsed = ''
      while !s.eos?
        s.scan(/(.*?)(<(\/)?(pre|code)(.*?)>|\z)/im)
        text, full_tag, closing, tag = s[1], s[2], s[3], s[4]
        if tags.empty?
          yield text
        end
        parsed << text
        if tag
          if closing
            if tags.last == tag.downcase
              tags.pop
            end
          else
            tags << tag.downcase
          end
          parsed << full_tag
        end
      end
      # Close any non closing tags
      while tag = tags.pop
        parsed << "</#{tag}>"
      end
      parsed
    end

    def host_name
      @host_name ||= select_host_name
    end

    def host_postfix
      @host_postfix ||= select_host_postfix.to_s
    end

    def select_host_name
      settings = select_all <<-SQL
        SELECT value FROM settings WHERE name = 'host_name'
      SQL

      settings.first['value']
    end

    def select_host_postfix
      host_postfix = /[a-z|\.|-]*(\/(?<host_postfix>.*))?/.match(host_name)[:host_postfix]

      host_postfix = "/#{host_postfix}" unless host_postfix.nil?

      host_postfix
    end

    def update_filter(columns)
      filter columns, ['issue', 'planning_element', '*']
    end

    def restore_filter(columns)
      filter columns, ['work_package', '#']
    end
  end
end
