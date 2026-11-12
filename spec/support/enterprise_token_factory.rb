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

module EnterpriseTokenFactory
  def self.included(base)
    base.before do
      EnterpriseToken.clear_current_tokens_cache

      # Calls are mocked in mock_token_object for enterprise tokens created by
      # tests. This line is to call normal implementation when not mocked.
      allow(OpenProject::Token).to receive(:import).and_call_original
    end
  end

  # Creates a new EnterpriseToken and saves it to the database.
  #
  # When calling `#token_object`, it returns a real `OpenProject::Token` object
  # built with the given attributes. `OpenProject::Token.import` is mocked to
  # return it when called with the encoded token name.
  #
  # A block can be given to perform additional actions on the created
  # EnterpriseToken, like with FactoryBot.
  #
  # @param encoded_token_name [String, nil] The encoded token name (optional);
  #   use a descriptive name to identify it more easily when debugging failing
  #   tests
  # @param attributes [Hash] The attributes for the inner `OpenProject::Token` object
  # @yield [EnterpriseToken] The `EnterpriseToken` instance
  # @return [EnterpriseToken] The created `EnterpriseToken`
  def create_enterprise_token(encoded_token_name = nil, **attributes)
    encoded_token_name ||= "token_#{SecureRandom.uuid}"
    enterprise_token = build_enterprise_token(encoded_token_name, **attributes) do |token|
      token.save!(validate: false)
    end
    yield enterprise_token if block_given?
    enterprise_token
  end

  # Builds a new EnterpriseToken without saving it to the database.
  #
  # When calling `#token_object`, it returns a real `OpenProject::Token` object
  # built with the given attributes. `OpenProject::Token.import` is mocked to
  # return it when called with the encoded token name.
  #
  # A block can be given to perform additional actions on the built
  # EnterpriseToken, like with FactoryBot.
  #
  # @param encoded_token_name [String, nil] The encoded token name (optional);
  #   use a descriptive name to identify it more easily when debugging failing
  #   tests
  # @param attributes [Hash] The attributes for the inner `OpenProject::Token` object
  # @yield [EnterpriseToken] The `EnterpriseToken` instance
  # @return [EnterpriseToken] The built `EnterpriseToken`
  def build_enterprise_token(encoded_token_name = nil, **attributes)
    encoded_token_name ||= "token"
    mock_token_object(encoded_token_name, **attributes)
    enterprise_token = EnterpriseToken.new(encoded_token: encoded_token_name)
    yield enterprise_token if block_given?
    enterprise_token
  end

  def mock_token_object(encoded_token_name, **attributes)
    token = OpenProject::Token.new(domain: Setting.host_name,
                                   starts_at: Date.yesterday,
                                   expires_at: 1.year.from_now,
                                   **attributes)
    allow(OpenProject::Token)
      .to receive(:import).with(encoded_token_name)
                          .and_return(token)
    token
  end
end
