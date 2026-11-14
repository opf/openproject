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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  class Jira < ApplicationRecord
    self.table_name = "jiras"

    enum :auth_method, { bearer: "bearer", basic: "basic" }, default: :bearer, prefix: true
    store_attribute :options, :exclude_resolution_fields, :boolean, default: false

    has_many :jira_imports, dependent: :destroy
    has_many :health_reports, as: :subject, dependent: :delete_all
    has_one :latest_health_report, -> { order(created_at: :desc, id: :desc) },
            as: :subject, class_name: "HealthReport", inverse_of: false, dependent: nil

    normalizes :url, with: ->(url) { url.strip }

    validate :url_must_be_http_or_https

    def client
      Import::JiraClient.new(url:,
                             auth_method:,
                             personal_access_token:,
                             basic_auth_username:,
                             basic_auth_password:)
    end

    def http_url?
      uri = URI.parse(url.to_s)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end

    private

    def url_must_be_http_or_https
      return if url.blank? || http_url?

      errors.add(:url, :invalid_url)
    end
  end
end
