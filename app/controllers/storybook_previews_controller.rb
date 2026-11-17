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

# Serves ViewComponent previews as bare HTML fragments for the Storybook
# experiment in storybook/. Storybook keeps the frontend assets loaded across
# stories, so previews render without a layout and the assets come from a
# separate endpoint.
class StorybookPreviewsController < ViewComponentsController
  layout false

  def assets; end

  def previews
    find_preview
    example = File.basename(params[:path])
    cast_params(@preview.instance_method(example)) if @preview.examples.include?(example)
    super
  end

  private

  def default_preview_layout = nil

  # Query strings only carry strings, so arguments are cast to the type of the
  # preview method's literal keyword default (e.g. `scheme: :default`).
  def cast_params(example_method)
    keyword_defaults(example_method).each do |name, default|
      next unless params.key?(name)

      params[name] = cast(params[name], default)
    end
  end

  def cast(value, default)
    case default
    when Symbol then value.to_sym
    when true, false then ActiveModel::Type::Boolean.new.cast(value)
    when Integer then value.to_i
    else value
    end
  end

  def keyword_defaults(example_method)
    Array(definition_node(example_method)&.parameters&.keywords)
      .grep(Prism::OptionalKeywordParameterNode)
      .to_h { |keyword| [keyword.name, literal(keyword.value)] }
  end

  def definition_node(example_method)
    file, line = example_method.source_location
    Prism.parse_file(file).value.breadth_first_search do |node|
      node.is_a?(Prism::DefNode) && node.name == example_method.name && node.location.start_line == line
    end
  end

  def literal(node)
    case node
    when Prism::SymbolNode then node.unescaped.to_sym
    when Prism::TrueNode then true
    when Prism::FalseNode then false
    when Prism::IntegerNode then node.value
    end
  end
end
