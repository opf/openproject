#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Authentication
  class OmniauthAuthHashContract
    include ActiveModel::Validations

    attr_reader :auth_hash

    def initialize(auth_hash)
      @auth_hash = auth_hash
    end

    validate :validate_auth_hash
    validate :validate_auth_hash_not_expired
    validate :validate_authorization_callback

    private

    def validate_auth_hash
      return if auth_hash&.valid?

      errors.add(:base, I18n.t(:error_omniauth_invalid_auth))
    end

    def validate_auth_hash_not_expired
      return unless auth_hash['timestamp']

      if auth_hash['timestamp'] < Time.now - 30.minutes
        errors.add(:base, I18n.t(:error_omniauth_registration_timed_out))
      end
    end

    def validate_authorization_callback
      return unless auth_hash&.valid?

      decision = OpenProject::OmniAuth::Authorization.authorized?(auth_hash)
      errors.add(:base, decision.message) unless decision.approve?
    end
  end
end
