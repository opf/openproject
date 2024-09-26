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
  class UpdateMetadataService
    attr_reader :user, :provider

    def initialize(user:, provider:)
      @user = user
      @provider = provider
    end

    def call
      apply_metadata(fetch_metadata)
    rescue StandardError => e
      OpenProject.logger.error(e)
      ServiceResult.failure(result: provider,
                            message: I18n.t("saml.metadata_parser.error", error: e.class.name))
    end

    private

    def apply_metadata(metadata)
      new_options = provider.options.merge(metadata)
      last_metadata_update = metadata.blank? ? nil : Time.current

      Saml::Providers::SetAttributesService
        .new(model: @provider, user: User.current, contract_class: Saml::Providers::UpdateContract)
        .call({ options: new_options, last_metadata_update: })
    end

    def fetch_metadata
      if provider.metadata_url.present?
        parse_url
      elsif provider.metadata_xml.present?
        parse_xml
      else
        {}
      end
    end

    def parse_xml
      parser_instance.parse_to_hash(provider.metadata_xml)
    end

    def parse_url
      parser_instance.parse_remote_to_hash(provider.metadata_url)
    end

    def parser_instance
      OneLogin::RubySaml::IdpMetadataParser.new
    end
  end
end
