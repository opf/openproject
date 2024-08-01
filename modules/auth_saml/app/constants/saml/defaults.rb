# frozen_string_literal: true

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
  module Defaults
    NAME_IDENTIFIER_FORMAT = 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'.freeze
    MAIL_MAPPING = %w[mail email Email emailAddress emailaddress
      urn:oid:0.9.2342.19200300.100.1.3 http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress].freeze

    FIRSTNAME_MAPPING = %w[givenName givenname given_name given_name
      urn:oid:2.5.4.42 http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname].freeze

    LASTNAME_MAPPING = %w[surname sur_name sn
      urn:oid:2.5.4.4 http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname].freeze

    REQUESTED_ATTRIBUTES = [
      {
        "name" => "mail",
        "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
        "friendly_name" => "Email address",
        "is_required" => true
      },
      {
        "name" => "givenName",
        "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
        "friendly_name" => "Given name",
        "is_required" => true
      },
      {
        "name" => "sn",
        "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
        "friendly_name" => "Family name",
        "is_required" => true
      }
    ].freeze
  end
end
