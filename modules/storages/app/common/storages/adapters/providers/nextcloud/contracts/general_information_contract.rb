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

module Storages
  module Adapters
    module Providers
      module Nextcloud
        module Contracts
          class GeneralInformationContract < ::ModelContract
            attribute :name
            validates :name, presence: true, length: { maximum: 255 }
            attribute :host
            validates :host, url: { message: :invalid_host_url }, length: { maximum: 255 }
            # Must run BEFORE nextcloud_compatible_host: that validator makes a live network
            # probe to the host, which must not happen before secure_context_uri has had a
            # chance to reject an unsafe new host.
            validates :host, secure_context_uri: true, unless: -> { errors.include?(:host) || !model.host_changed? }
            # Check that a host actually is a storage server.
            # But only do so if the validations above were successful.
            validates :host, nextcloud_compatible_host: true, unless: -> { errors.include?(:host) }

            attribute :authentication_method
            validates :authentication_method, presence: true, inclusion: { in: NextcloudStorage::AUTHENTICATION_METHODS }

            validate :require_ee_token_for_sso

            def require_ee_token_for_sso
              return if EnterpriseToken.allows_to?(:nextcloud_sso)
              return unless model.authenticate_via_idp?
              return unless model.authentication_method_changed?

              plan_name = I18n.t("ee.upsell.plan_name", plan: OpenProject::Token.lowest_plan_for(:nextcloud_sso)&.capitalize)
              errors.add(:authentication_method, :enterprise_plan_required, plan_name:)
            end
          end
        end
      end
    end
  end
end
