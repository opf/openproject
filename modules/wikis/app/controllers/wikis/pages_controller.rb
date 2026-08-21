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
    include PageSelectionFormInput
    include Concerns::ErrorHandling
    include Concerns::LinkableRedirect
    include OpTurbo::ComponentStream

    before_action :authorize, except: %i[search browse]

    # search and browse are project independent and thus permission independent. The user will see results according to
    # the permissions set in each wiki.
    no_authorization_required! :search, :browse

    def create_and_link # rubocop:disable Metrics/AbcSize
      parameters = create_new_page_params
      provider = Provider.visible.enabled.find(parameters[:provider_id])

      CreatePageService
        .new(provider:, user: current_user)
        .create_page_and_link(
          title: parameters[:page_title],
          parent_identifier: parameters[:parent_identifier],
          parent_type: parameters[:parent_type],
          linkable_type: parameters[:linkable_type],
          linkable_id: parameters[:linkable_id]
        )
        .either(
          ->(page_link) { turbo_redirect_for_linkable(page_link.linkable) },
          ->(error) do
            render_error_flash_message_via_turbo_stream(message: humanize_error_message(error))
            respond_to_with_turbo_streams
          end
        )
    end

    def create_new_page_dialog
      parameters = create_new_page_params
      form_object = Forms::CreateNewWikiPageFormModel.new(linkable_id: parameters[:linkable_id],
                                                          linkable_type: parameters[:linkable_type],
                                                          provider_id: parameters[:provider_id],
                                                          page_title: parameters[:page_title])
      respond_with_dialog Wikis::CreateNewWikiPageDialog.new(form_object)
    end

    def search
      query, name = params.values_at(:query, :name)
      builder = form_builder

      if query.blank?
        render_browsing_tree(name, builder)
      else
        search_pages(query, fetch_provider).either(
          ->(pages) {
            render(Wikis::SearchPagesResultComponent.new(pages, form_name: name, builder:, wikis_selectable:), layout: false)
          },
          ->(failure) { render "search_error", layout: false, locals: { message: humanize_error_message(failure) } }
        )
      end
    end

    def browse
      path = JSON.parse(params[:path])

      browse_pages(params.expect(:parent)).either(
        ->(pages) {
          render(Wikis::BrowsePagesFragmentComponent.new(pages, path, fetch_provider.id, wikis_selectable:), layout: false)
        },
        ->(failure) { render "search_error", layout: false, locals: { message: humanize_error_message(failure) } }
      )
    end

    private

    def render_browsing_tree(name, builder)
      browse_pages(nil).either(
        ->(pages) { render Wikis::BrowsePagesComponent.new(pages, builder, name, fetch_provider.id, wikis_selectable:) },
        ->(failure) { render "search_error", layout: false, locals: { message: humanize_error_message(failure) } }
      )
    end

    def fetch_provider
      Provider.visible.enabled.find(params.expect(:provider_id))
    end

    def wikis_selectable
      ActiveModel::Type::Boolean.new.cast(params[:wikis_selectable]) || false
    end

    def form_builder
      ActionView::Helpers::FormBuilder.new("", nil, view_context, {})
    end

    def search_pages(query, provider)
      PageSearchService.new(provider:, user: current_user).search_pages(query)
    end

    def browse_pages(parent_identifier)
      BrowsePagesService.new(provider: fetch_provider, user: current_user).call(parent_identifier)
    end

    def create_new_page_params
      parent = parse_selected_node(params[:wiki_page_selection])

      params.expect(wikis_forms_create_new_wiki_page_form_model: %i[provider_id linkable_type linkable_id page_title])
            .merge(parent_identifier: parent&.identifier, parent_type: parent&.type)
    end
  end
end
