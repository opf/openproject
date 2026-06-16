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
    include Dry::Monads[:result]

    # The view component shown in `load` will be rendered regardless of the current user's authorization status.
    # The component itself handles the states of "unauthorized", "forbidden", and "not_found".
    authorization_checked! :load

    def load
      provider = Provider.visible.find_by(id: params[:provider_id])
      @page_info_result = page_info_result(provider)
      @turbo_frame_id = turbo_frame_id

      render layout: false
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
  end
end
