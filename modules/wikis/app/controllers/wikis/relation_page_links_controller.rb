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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Wikis
  class RelationPageLinksController < ApplicationController
    include OpTurbo::ComponentStream

    before_action :authorize

    def create
      service_result = RelationPageLinks::CreateService.new(user: current_user).call(relation_page_link_params)
      if service_result.success?
        page_link = service_result.result
        turbo_redirect_for_linkable(page_link.linkable)
      else
        message = service_result.errors.full_messages.join(" ")
        render_error_flash_message_via_turbo_stream(message:)
        respond_to_with_turbo_streams
      end
    end

    def destroy
      page_link = find_page_link
      service_result = Wikis::RelationPageLinks::DeleteService.new(user: current_user, model: page_link).call
      if service_result.success?
        turbo_redirect_for_linkable(page_link.linkable)
      else
        message = service_result.errors.full_messages.join(" ")
        render_error_flash_message_via_turbo_stream(message:)
        respond_to_with_turbo_streams
      end
    end

    def confirm_delete_dialog
      page_link = find_page_link
      respond_with_dialog(DeleteRelationPageLinkConfirmationDialog.new(page_link:))
    end

    def link_existing_dialog
      linkable = WorkPackage.visible.find(params.expect(:work_package))
      provider = Provider.visible.find(params.expect(:provider))
      respond_with_dialog Wikis::LinkExistingWikiPageDialog.new(linkable:, provider:)
    end

    private

    def find_page_link
      RelationPageLink.find(params.expect(:id))
    end

    def relation_page_link_params
      params.expect(wikis_relation_page_link: %i[provider_id linkable_type linkable_id])
            .merge(author_id: current_user.id, identifier: parse_identifier(params[:wiki_page_selection]))
    end

    def parse_identifier(wiki_page_selection)
      case wiki_page_selection
      in [selected_page]
        MultiJson.load(selected_page, symbolize_keys: true)[:value]
      else
        nil
      end
    end

    def turbo_redirect_for_linkable(linkable)
      path = derive_path_from_linkable(linkable)
      return redirect_to path, status: :see_other if path

      head :no_content
    end

    def derive_path_from_linkable(linkable)
      case linkable
      when WorkPackage
        project_work_package_wikis_tab_index_path(work_package_id: linkable.id, project_id: linkable.project_id)
      end
    end
  end
end
