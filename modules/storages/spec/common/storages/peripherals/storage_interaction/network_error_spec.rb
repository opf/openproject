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

require 'spec_helper'
require_module_spec_helper

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'network errors for storage interaction' do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
  let(:folder) { Storages::Peripherals::ParentFolder.new('/') }
  let(:auth_strategy) do
    Storages::Peripherals::StorageInteraction::AuthenticationStrategies::OAuthUserToken.strategy.with_user(user)
  end

  subject do
    Storages::Peripherals::StorageInteraction::OneDrive::FilesQuery.new(storage)
  end

  context 'if a timeout happens' do
    before do
      request = HTTPX::Request.new(:get, 'https://my.timeout.org/')
      httpx_double = class_double(HTTPX, get: HTTPX::ErrorResponse.new(request, 'Timeout happens', {}))
      allow(httpx_double).to receive(:with).and_return(httpx_double)
      allow(OpenProject).to receive(:httpx).and_return(httpx_double)
    end

    it 'must return an error with wrapped network error response' do
      error = subject.call(auth_strategy:, folder:)
      expect(error).to be_failure
      expect(error.result).to eq(:error)
      expect(error.error_payload).to be_a(HTTPX::ErrorResponse)
    end
  end
end
# rubocop:enable RSpec/DescribeClass
