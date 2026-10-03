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

module Collaboration
  module SessionContext
    private

    def setup_collaboration_context(resource) # rubocop:disable Metrics/AbcSize
      return unless resource.collaboration_viewable_by?(current_user)

      token_result = Collaboration::OAuth::TokenWithMetadataService
        .new(user: current_user, resource:)
        .call

      if token_result.failure?
        Rails.logger.error("Failed to generate token payload for #{resource.model_name.singular} #{resource.id}: " \
                           "#{token_result.errors}")
        return
      end

      @token_payload = token_result.result[:encrypted_token]
      @resource_url = token_result.result[:resource_url]
      @readonly = token_result.result[:readonly]
      @token_expires_in_seconds = token_result.result[:expires_in_seconds]
    end
  end
end
