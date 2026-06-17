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
  class PageLinkMacroController < ApplicationController
    include OpTurbo::ComponentStream
    include Concerns::ErrorHandling
    include PageSelectionFormInput
    include Dry::Monads[:result]

    # The view component shown in `load` will be rendered regardless of the current user's authorization status.
    # The component itself handles the states of "unauthorized", "forbidden", and "not_found".
    # The dialogs rendered here will perform global wiki page searches and will result in inserting a link view
    # component rendered with `load`.
    authorization_checked! :load,
                           :existing_page_dialog,
                           :new_page_dialog,
                           :close_existing_page_dialog,
                           :close_new_page_dialog

    def load
      provider = Provider.visible.enabled.find_by(id: params[:provider_id])
      @page_info_result = page_info_result(provider)
      @turbo_frame_id = turbo_frame_id

      render layout: false
    end

    def existing_page_dialog
      provider_id = inline_existing_params[:provider_id]
      if provider_id.blank? && Provider.visible.enabled.one?
        # If no provider data was passed and there is only one enabled provider, use it by default
        provider_id = Provider.visible.enabled.first.id
      end

      form_model = Forms::InlineExistingWikiPageFormModel.new(provider_id:)
      respond_with_dialog Wikis::InlineWikiPageDialog.new(form_model)
    end

    def new_page_dialog
      parameters = inline_new_params
      form_model = Forms::InlineNewWikiPageFormModel.new(provider_id: parameters[:provider_id],
                                                         page_title: parameters[:page_title])
      respond_with_dialog Wikis::InlineWikiPageDialog.new(form_model)
    end

    def close_existing_page_dialog
      params = inline_existing_params
      close_dialog_via_turbo_stream("##{InlineWikiPageDialog::DIALOG_ID}",
                                    additional: {
                                      action: "close_existing_page_dialog",
                                      providerId: params[:provider_id],
                                      pageIdentifier: params[:page_identifier]
                                    })
      respond_with_turbo_streams
    end

    def close_new_page_dialog # rubocop:disable Metrics/AbcSize
      parameters = inline_new_params

      provider = Provider.visible.enabled.find(parameters[:provider_id])
      result = CreatePageService.new(provider:, user: current_user)
                                .create_page(title: parameters[:page_title],
                                             parent_identifier: parameters[:parent_page_identifier])

      result.either(
        ->(info) do
          close_dialog_via_turbo_stream("##{InlineWikiPageDialog::DIALOG_ID}",
                                        additional: {
                                          action: "close_new_page_dialog",
                                          providerId: provider.id,
                                          pageIdentifier: info.identifier
                                        })
        end,
        ->(error) { render_error_flash_message_via_turbo_stream(message: humanize_error_message(error)) }
      )

      respond_with_turbo_streams
    end

    private

    def page_info_result(provider)
      return Failure() if provider.nil?

      Adapters::Input::PageInfo.build(identifier:).bind do |input_data|
        provider.auth_strategy_for(User.current).bind do |auth_strategy|
          provider.resolve("queries.page_info").call(input_data:, auth_strategy:)
        end
      end
    end

    def identifier
      params[:page_identifier]
    end

    def turbo_frame_id
      params[:turbo_frame_id]
    end

    def inline_existing_params
      if params.key?(:wikis_forms_inline_existing_wiki_page_form_model)
        params.expect(wikis_forms_inline_existing_wiki_page_form_model: %i[provider_id])
              .merge(page_identifier: parse_identifier(params[:wiki_page_selection]))
      else
        params
      end
    end

    def inline_new_params
      if params.key?(:wikis_forms_inline_new_wiki_page_form_model)
        params.expect(wikis_forms_inline_new_wiki_page_form_model: %i[provider_id page_title])
              .merge(parent_page_identifier: parse_identifier(params[:wiki_page_selection]))
      else
        params
      end
    end
  end
end
