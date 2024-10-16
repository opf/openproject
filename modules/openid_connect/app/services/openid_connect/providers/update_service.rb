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

module OpenIDConnect
  module Providers
    class UpdateService < BaseServices::Update
      class AttributesContract < Dry::Validation::Contract
        params do
          OpenIDConnect::Provider::DISCOVERABLE_ATTRIBUTES_MANDATORY.each do |attribute|
            required(attribute).filled(:string)
          end
          OpenIDConnect::Provider::DISCOVERABLE_ATTRIBUTES_OPTIONAL.each do |attribute|
            optional(attribute).filled(:string)
          end
        end
      end

      def after_validate(_params, call)
        model = call.result
        metadata_url = get_metadata_url(model)
        return call if metadata_url.blank?

        extract_metadata(call, metadata_url, model)
      end

      def extract_metadata(call, metadata_url, model) # rubocop:disable Metrics/AbcSize
        case (response = OpenProject.httpx.get(metadata_url))
        in {status: 200..299}
          json = begin
            response.json
          rescue HTTPX::Error
            call.errors.add(:metadata_url, :response_is_not_json)
            call.success = false
          end
          result = AttributesContract.new.call(json)
          if result.errors.empty?
            model.assign_attributes(result.to_h)
            # Microsoft responds with
            # "https://login.microsoftonline.com/{tenantid}/v2.0" in issuer field for whatever reason...
            if model.oidc_provider == "microsoft_entra"
              model.issuer = "https://login.microsoftonline.com/#{model.tenant}/v2.0"
            end
          else
            call.errors.add(:metadata_url,
                            :response_misses_required_attributes,
                            missing_attributes: result.errors.attribute_names.join(", "))
            call.success = false
          end
        in {status: 300..}
          call.errors.add(:metadata_url, :response_is_not_successful, status: response.status)
          call.success = false
        in {error: error}
          call.message = error.message
          call.success = false
        else
          call.message = I18n.t(:notice_internal_server_error)
          call.success = false
        end

        call
      end

      def get_metadata_url(model)
        case model.oidc_provider
        when "google"
          "https://accounts.google.com/.well-known/openid-configuration"
        when "microsoft_entra"
          "https://login.microsoftonline.com/#{model.tenant || 'common'}/v2.0/.well-known/openid-configuration"
        else
          model.metadata_url
        end
      end
    end
  end
end
