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

module SquashTMIntegration
  class Server < ApplicationRecord
    include Redmine::Ciphering

    self.table_name = "squashtm_servers"

    validate :single_server, on: :create

    def self.current
      first || new
    end

    def self.configured?
      exists?
    end

    def api_token
      read_ciphered_attribute(:api_token)
    end

    # Redmine::Ciphering would encrypt nil into the ciphertext of an empty string.
    def api_token=(value)
      if value.present?
        write_ciphered_attribute(:api_token, value)
      else
        write_attribute(:api_token, nil)
      end
    end

    def api_token_stored?
      persisted? && api_token_in_database.present?
    end

    def test_case_url(test_case_id)
      web_url("test-case-workspace/test-case/#{Integer(test_case_id)}/content", anchor: "information")
    end

    def requirement_url(requirement_id)
      web_url("requirement-workspace/requirement-library/#{Integer(requirement_id)}/content", anchor: "dashboard")
    end

    private

    def web_url(path, anchor:)
      "#{base_url.chomp('/')}/#{path}?#{{ anchor: }.to_query}"
    end

    def single_server
      errors.add(:base, :singleton) if self.class.exists?
    end
  end
end
