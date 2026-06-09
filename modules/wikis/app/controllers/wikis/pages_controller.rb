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
  class PagesController < ApplicationController
    include OpTurbo::ComponentStream
    include Dry::Monads[:result]

    before_action :authorize, except: %i[search]

    # The search is project independent and thus permission independent. The user will see results according to
    # the permissions set in each wiki.
    no_authorization_required! :search

    def create_and_link
      # TODO: implement service to create page and link
      render_error_flash_message_via_turbo_stream(
        message: "Not implemented yet. Trying to create a new page with #{create_new_page_params.to_h}"
      )
      respond_to_with_turbo_streams
    end

    def create_new_page_dialog
      params = create_new_page_params
      form_object = Forms::CreateNewWikiPageFormModel.new(linkable_id: params[:linkable_id],
                                                          linkable_type: params[:linkable_type],
                                                          provider_id: params[:provider_id],
                                                          page_title: params[:page_title])
      respond_with_dialog Wikis::CreateNewWikiPageDialog.new(form_object)
    end

    def search
      provider = Provider.visible.find(params.expect(:provider_id))
      query = params[:query]
      form_name = params[:name]
      builder = ActionView::Helpers::FormBuilder.new("", nil, view_context, {})
      search_result = search_pages(query, provider)

      render layout: false, locals: { search_result:, builder:, name: form_name }
    end

    private

    def search_pages(query, provider)
      return Success([]) if query.blank?

      Adapters::Input::SearchPages.build(query:).bind do |input_data|
        provider.auth_strategy_for(current_user).bind do |auth_strategy|
          provider.resolve("queries.search_pages").call(input_data:, auth_strategy:)
        end
      end
    end

    def create_new_page_params
      params.expect(wikis_forms_create_new_wiki_page_form_model: %i[provider_id linkable_type linkable_id page_title])
            .merge(parent_page_identifier: parse_identifier(params[:wiki_page_selection]))
    end

    def parse_identifier(wiki_page_selection)
      case wiki_page_selection
      in [selected_page]
        MultiJson.load(selected_page, symbolize_keys: true)[:value]
      else
        nil
      end
    end
  end
end
