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

module Exports::PDF::Common::Styles
  include MarkdownToPDF::StyleValidation

  def initialize(styles_asset_path, style_yml_file = "standard.yml", schema_json_file = "schema.json")
    yml = YAML::load_file(File.join(styles_asset_path, style_yml_file))
    schema = JSON::load_file(File.join(styles_asset_path, schema_json_file))
    validate_schema!(yml, schema)
    @styles = yml.deep_symbolize_keys
  end

  protected

  def resolve_pt(value, default)
    parse_pt(value) || default
  end

  def resolve_table_cell(style)
    # prawn.table.make_cell does use differently named options
    # so to have them specified consistently, we map here
    opts = opts_table_cell(style || {})
    font_styles = opts.delete(:styles) || []
    opts[:font_style] = font_styles[0] unless font_styles.empty?
    color = opts.delete(:color)
    opts[:text_color] = color unless color.nil?
    opts
  end

  def resolve_markdown_styling(style)
    page = style.delete(:font)
    style[:page] = page unless page.nil?
    style
  end

  def resolve_borders(style)
    opts_borders(style || {})
  end

  def resolve_font(style)
    opts_font(style || { size: 10 })
  end

  def resolve_margin(style)
    opts_margin(style || {})
  end

  def resolve_padding(style)
    opts_padding(style || {})
  end
end
