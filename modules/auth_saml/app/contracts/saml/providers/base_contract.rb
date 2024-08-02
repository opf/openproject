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
module Saml
  module Providers
    class BaseContract < ModelContract
      include RequiresAdminGuard

      def self.model
        Saml::Provider
      end

      attribute :display_name
      attribute :options
      attribute :metadata_url
      validates :metadata_url,
                url: { allow_blank: true, allow_nil: true, schemes: %w[http https] },
                if: -> { model.metadata_url_changed? }

      attribute :idp_sso_service_url
      validates :idp_sso_service_url,
                url: { schemes: %w[http https] },
                if: -> { model.idp_sso_service_url_changed? }

      attribute :idp_slo_service_url
      validates :idp_slo_service_url,
                url: { schemes: %w[http https] },
                if: -> { model.idp_slo_service_url_changed? }

      %i[mapping_mail mapping_login mapping_firstname mapping_lastname].each do |attr|
        attribute attr
        validates_presence_of attr
      end
    end
  end
end
