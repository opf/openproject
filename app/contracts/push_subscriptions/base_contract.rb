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

module PushSubscriptions
  class BaseContract < ::ModelContract
    # Keeps every endpoint below the PostgreSQL btree entry limit the unique index on it has to respect.
    MAX_ENDPOINT_LENGTH = 2048

    attribute :user_id
    attribute :session_id
    attribute :suspended_at
    attribute :endpoint
    attribute :browser_name
    attribute :browser_version
    attribute :platform

    validate :validate_owner
    validate :validate_session
    validate :validate_endpoint

    def self.model = ::PushSubscription

    private

    def validate_owner
      errors.add(:base, :error_unauthorized) unless model.user_id == user.id
    end

    def validate_session
      if model.session_id.blank?
        errors.add(:session_id, :blank)
      elsif !Sessions::UserSession.exists?(id: model.session_id, user_id: user.id)
        errors.add(:session_id, :invalid)
      end
    end

    def validate_endpoint
      errors.add(:endpoint, :invalid) unless push_service_endpoint?
    end

    def push_service_endpoint?
      return false if model.endpoint.blank? || model.endpoint.length > MAX_ENDPOINT_LENGTH

      uri = parse_endpoint
      uri.is_a?(URI::HTTPS) && uri.port == 443 && uri.userinfo.nil? && OpenProject::WebPush.push_service_host?(uri.host)
    end

    def parse_endpoint
      URI.parse(model.endpoint)
    rescue URI::InvalidURIError
      nil
    end
  end
end
