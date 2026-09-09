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

module ::ResourceManagement
  class PlaceholderUsersController < BaseController
    include OpTurbo::ComponentStream

    before_action :authorize_global

    def new
      respond_with_dialog ResourceManagement::PlaceholderUsers::NewDialogComponent.new(
        placeholder_user: PlaceholderUser.new(name: params[:name])
      )
    end

    def create
      call = ::PlaceholderUsers::CreateService
               .new(user: current_user)
               .call(create_attributes)

      if call.success?
        render_create_success(call.result)
      else
        render_create_failure(call.result)
      end
    end

    private

    def render_create_success(placeholder_user)
      close_dialog_via_turbo_stream(
        ResourceManagement::PlaceholderUsers::NewDialogComponent::DIALOG_ID,
        additional: { placeholderUserId: placeholder_user.id }
      )
      respond_with_turbo_streams
    end

    def render_create_failure(placeholder_user)
      replace_via_turbo_stream(
        component: ResourceManagement::PlaceholderUsers::FormComponent.new(placeholder_user:),
        status: :unprocessable_entity
      )
      respond_with_turbo_streams(status: :unprocessable_entity)
    end

    def create_attributes
      params
        .expect(placeholder_user: %i[name description])
        .to_h
        .symbolize_keys
        .merge(user_filter: submitted_user_filter)
    end

    # The filter builder submits its selection as a JSON string in a top-level
    # `filters` field, outside the model scope.
    def submitted_user_filter
      query = UserQuery.new
      ::Queries::ParamsParser
        .parse(filters: params[:filters])
        .fetch(:filters, [])
        .each { |filter| query.where(filter[:attribute], filter[:operator], filter[:values]) }

      query.filters
    end
  end
end
