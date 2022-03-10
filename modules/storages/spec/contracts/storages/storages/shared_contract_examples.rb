#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
require_relative '../../../support/storage_server_helpers'

shared_examples_for 'storage contract', :storage_server_helpers, webmock: true do
  # Only admins have the right to create/delete storages.
  let(:current_user) { create(:admin) }
  let(:storage_name) { 'Storage 1' }
  let(:storage_provider_type) { 'nextcloud' }
  let(:storage_host) { 'https://host1.example.com' }
  let(:storage_creator) { current_user }
  let(:host_response_code) { '200' }
  let(:host_response_message) { 'OK' }
  let(:host_response_major_version) { 23 }

  before do
    if storage_host.present?
      mock_server_capabilities_response(storage_host,
                                        response_code: host_response_code,
                                        response_nextcloud_major_version: host_response_major_version)
    end
  end

  it_behaves_like 'contract is valid for active admins and invalid for regular users'

  describe 'validations' do
    context 'when all attributes are valid' do
      it_behaves_like 'contract is valid'
    end

    context 'when name is invalid' do
      context 'as it is too long' do
        let(:storage_name) { 'X' * 257 }

        it_behaves_like 'contract is invalid'
      end

      context 'as it is empty' do
        let(:storage_name) { '' }

        it_behaves_like 'contract is invalid'
      end

      context 'as it is nil' do
        let(:storage_name) { nil }

        it_behaves_like 'contract is invalid'
      end
    end

    context 'when provider_type is invalid' do
      context 'as it is unknown' do
        let(:storage_provider_type) { 'unkwown_provider_type' }

        it_behaves_like 'contract is invalid'
      end

      context 'as it is empty' do
        let(:storage_provider_type) { '' }

        it_behaves_like 'contract is invalid'
      end

      context 'as it is nil' do
        let(:storage_provider_type) { nil }

        it_behaves_like 'contract is invalid'
      end
    end

    context 'when host is invalid' do
      context 'as host is not a URL' do
        let(:storage_host) { '---invalid-url---' }

        it_behaves_like 'contract is invalid'
      end

      context 'as host is an empty string' do
        let(:storage_host) { '' }

        it_behaves_like 'contract is invalid'
      end

      context 'as host is nil' do
        let(:storage_host) { nil }

        it_behaves_like 'contract is invalid'
      end

      context 'when provider_type is nextcloud' do
        before do
          # simulate host value changed to have GET request sent to check host URL validity
          storage.host_will_change!
        end

        context 'when response code is a 404 NOT FOUND' do
          let(:host_response_code) { '404' }

          it_behaves_like 'contract is invalid'
        end

        context 'when response code is a 500 PERMISSION DENIED' do
          let(:host_response_code) { '500' }

          it_behaves_like 'contract is invalid'
        end

        context 'when Nextcloud version is below the required minimal version which is 23' do
          let(:host_response_major_version) { '22' }

          it_behaves_like 'contract is invalid'
        end
      end
    end
  end
end
