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
  class MetadataParserService
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def parse_url(url)
      validate_url!(url)
      parse_remote_metadata(url)
    rescue URI::InvalidURIError
      ServiceResult.failure(message: I18n.t('saml.metadata_parser.invalid_url'))
    rescue OneLogin::RubySaml::HttpError => e
      ServiceResult.failure(message: I18n.t('saml.metadata_parser.error', error: e.message))
    rescue StandardError => e
      OpenProject.logger.error(e)
      ServiceResult.failure(message: I18n.t('saml.metadata_parser.error', error: e.class.name))
    end

    def parse_remote_metadata(metadata_url)
      idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
      result = idp_metadata_parser.parse_remote_to_hash(metadata_url)

      ServiceResult.success(result:)
    end

    def validate_url!(url)
      uri = URI.parse(url)
      raise URI::InvalidURIError unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    end
  end
end
