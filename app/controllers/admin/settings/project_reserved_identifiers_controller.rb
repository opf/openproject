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

module Admin::Settings
  class ProjectReservedIdentifiersController < ::ApplicationController
    include OpTurbo::ComponentStream
    include PaginationHelper

    before_action :require_admin
    before_action :require_classic_mode
    before_action :find_slug, only: %i[confirm_dialog destroy]

    menu_item :project_reserved_identifiers_settings

    layout "admin"

    def index
      @query = build_query
      @slugs = @query.results
        .includes(:sluggable)
        .paginate(page: page_param, per_page: per_page_param)
    end

    def search
      index
      replace_via_turbo_stream(
        component: Admin::Settings::ProjectReservedIdentifiers::IndexComponent.new(@slugs)
      )
      current_url = admin_settings_project_reserved_identifiers_path(params.permit(:filters))
      turbo_streams << turbo_stream.push_state(current_url)
      respond_with_turbo_streams
    end

    def confirm_dialog
      respond_with_dialog Admin::Settings::ProjectReservedIdentifiers::ReleaseDialogComponent.new(slug: @slug)
    end

    def destroy
      @slug.destroy!
      redirect_to admin_settings_project_reserved_identifiers_path,
                  flash: { notice: t("admin.reserved_identifiers.released_notice", identifier: @slug.slug) }
    end

    private

    def find_slug
      @slug = Project.identifier_slugs.historically_reserved.find(params.expect(:id))
    rescue ActiveRecord::RecordNotFound
      render_error_flash_message_via_turbo_stream(
        message: t("admin.reserved_identifiers.identifier_not_found")
      )
      respond_with_turbo_streams(status: :not_found)
    end

    def build_query
      ParamsToQueryService
        .new(FriendlyId::Slug, current_user,
             query_class: Queries::ProjectReservedIdentifiers::ProjectReservedIdentifierQuery)
        .call(params)
    end

    def require_classic_mode
      return unless Setting::WorkPackageIdentifier.semantic?

      redirect_to admin_settings_work_packages_identifier_path,
                  flash: { warning: t("admin.reserved_identifiers.not_available_in_semantic_mode") }
    end
  end
end
