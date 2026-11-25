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

module WorkPackageTypes
  module AdminTypesList
    extend ActiveSupport::Concern

    included do
      include PaginationHelper
    end

    private

    def admin_types_list_component(expanded_type_id: admin_types_expanded_type_id)
      Types::GroupedListComponent.new(
        types: admin_types_scope,
        page_args: admin_types_page_args,
        expanded_type_id:
      )
    end

    def admin_types_scope
      scope = ::Type
        .includes(:color, :projects,
                  variants: [:workflow, { form_configuration: :custom_fields }])
      scope = scope.with_own_or_variant_name_like(params[:query]) if params[:query].present?
      scope = scope.with_migrated_variants if admin_types_migration_filter?

      scope
        .page(page_param)
        .per_page(per_page_param)
    end

    def admin_types_page_args
      { page: page_param, per_page: per_page_param }
    end

    def admin_types_migration_filter?
      params[:created_by_migration].presence == WorkPackageTypes::MigrationFilterComponent::MIGRATED
    end

    def admin_types_filtered? = params[:query].present? || admin_types_migration_filter?

    def admin_types_expanded_type_id
      Integer(params[:expand].to_s, exception: false)
    end
  end
end
