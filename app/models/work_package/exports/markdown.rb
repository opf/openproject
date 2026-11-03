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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackage::Exports::Markdown < Exports::Exporter
  include WorkPackage::Exports::Attributes
  include Exports::PDF::Common::Macro

  self.model = WorkPackage

  def self.key = :md

  def export!
    Exports::Result.new(format: :md,
                        title: "#{work_package.display_id}.md",
                        mime_type: "text/markdown",
                        content:)
  end

  private

  alias_method :work_package, :object

  def content
    blocks = [title_block, header_block, *group_blocks, *description_blocks]
    "#{blocks.join("\n\n")}\n"
  end

  def title_block
    "# #{work_package.type} #{work_package.formatted_id} - #{work_package.subject}"
  end

  def header_block
    [
      "#{WorkPackage.human_attribute_name(:project)}: #{work_package.project.name}",
      "#{WorkPackage.human_attribute_name(:status)}: #{work_package.status.name}",
      "#{WorkPackage.human_attribute_name(:url)}: #{url_helpers.work_package_url(work_package)}"
    ].join("\n")
  end

  def group_blocks
    WorkPackage::Exports::FormConfiguration.new(work_package).groups.flat_map do |group|
      case group
      when WorkPackage::Exports::FormConfiguration::AttributeGroup then attribute_group_blocks(group)
      when WorkPackage::Exports::FormConfiguration::QueryGroup then query_group_blocks(group)
      end
    end
  end

  def attribute_group_blocks(group)
    ["## #{group.title}", *group.parts.flat_map { |part| part_blocks(part) }]
  end

  def part_blocks(part)
    case part
    when WorkPackage::Exports::FormConfiguration::AttributesPart then [attributes_table(part.entries)]
    when WorkPackage::Exports::FormConfiguration::LongTextPart then ["### #{part.label}", *markdown_blocks(part.markdown)]
    end
  end

  def attributes_table(entries)
    rows = entries.map { |entry| [entry.label, formatter_for(entry.name, :md).format(work_package)] }
    table([I18n.t(:label_attribute), I18n.t(:label_value)], rows)
  end

  def query_group_blocks(group)
    ["## #{group.title}", query_table(group.query, group.work_packages)]
  end

  def query_table(query, work_packages)
    return "_#{I18n.t(:label_x_work_packages, count: 0)}_" if work_packages.empty?

    columns = query.columns.grep_v(Queries::WorkPackages::Selects::RelationSelect)
    rows = work_packages.map do |related|
      columns.map { |column| query_cell(related, column.name) }
    end
    table(columns.map(&:caption), rows)
  end

  def query_cell(related, name)
    return "" unless allowed_to_view_attribute?(related, name)

    formatter_for(name, :md).format(related)
  end

  def description_blocks
    return [] if work_package.description.blank?

    ["## #{WorkPackage.human_attribute_name(:description)}", *markdown_blocks(work_package.description)]
  end

  def markdown_blocks(markdown)
    expanded = apply_markdown_field_macros(markdown, { work_package:, project: work_package.project, user: current_user })
    normalized = expanded.to_s.gsub(/\r\n?/, "\n").rstrip
    normalized.empty? ? [] : [normalized]
  end

  def table(header, rows)
    [
      table_row(header),
      table_row(header.map { "---" }),
      *rows.map { |row| table_row(row) }
    ].join("\n")
  end

  def table_row(cells)
    "| #{cells.map { |cell| escape_cell(cell) }.join(' | ')} |"
  end

  def escape_cell(value)
    value.to_s.gsub("\\") { "\\\\" }.gsub("|") { "\\|" }.gsub(/\r\n?|\n/, " ")
  end

  def url_helpers
    @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
  end
end
