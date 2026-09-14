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

module WorkPackageTypes
  module ProjectsTab
    class VariantFilterComponent < OpPrimer::QuickFilter::SelectPanelComponent
      def initialize(type:, variant:, query:)
        @type = type
        @variant = variant

        super(name: TypeVariant.model_name.human, query:, filter_key: :type_variant_id, path_args: [])

        type.variants.in_display_order.each do |sibling|
          with_item(label: "#{sibling.composite_name} (#{project_counts[sibling.id]})", value: sibling.id)
        end
      end

      private

      def project_counts
        @project_counts ||= Hash.new(0).merge(
          ProjectType.where(type_id: @type.id).group(:variant_id).count
        )
      end

      def base_url = tab_path(base_url_params)

      def item_href(value)
        selected = other_filters + [{ @filter_key.to_s => { "operator" => @operator, "values" => [value.to_s] } }]

        tab_path(filters: selected.to_json)
      end

      def tab_path(params)
        helpers.edit_type_projects_path(**@variant.path_args, **params)
      end
    end
  end
end
