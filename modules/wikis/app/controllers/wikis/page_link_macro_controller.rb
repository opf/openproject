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
    include PageSelectionFormInput
    include Dry::Monads[:result]

    # The view component shown in `load` will be rendered regardless of the current user's authorization status.
    # The component itself handles the states of "unauthorized", "forbidden", and "not_found".
    # The dialogs rendered here will perform global wiki page searches and will result in inserting a link view
    # component rendered with `load`.
    authorization_checked! :load, :inline_existing_page_dialog, :close_dialog_and_inline

    def load
      provider = Provider.visible.find_by(id: params[:provider_id])
      @page_info_result = page_info_result(provider)
      @turbo_frame_id = turbo_frame_id

      render layout: false
    end

    def inline_existing_page_dialog
      provider_id = inline_existing_params[:provider_id]
      if provider_id.blank? && Provider.visible.enabled.one?
        # If no provider data was passed and there is only one enabled provider, use it by default
        provider_id = Provider.visible.enabled.first.id
      end

      form_model = Forms::InlineExistingWikiPageFormModel.new(provider_id:)
      respond_with_dialog Wikis::InlineExistingWikiPageDialog.new(form_model)
    end

    def close_dialog_and_inline
      params = inline_existing_params
      close_dialog_via_turbo_stream("##{InlineExistingWikiPageDialog::DIALOG_ID}",
                                    additional: {
                                      action: "close_dialog_and_inline",
                                      providerId: params[:provider_id],
                                      pageIdentifier: params[:page_identifier]
                                    })
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
  end
end
