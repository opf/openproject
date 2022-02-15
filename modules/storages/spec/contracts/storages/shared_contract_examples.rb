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

shared_examples_for 'storage contract', webmock: true do
  let(:storage_name) { 'Storage 1' }
  let(:storage_provider_type) { 'nextcloud' }
  let(:storage_host) { 'http://host1.example.com' }
  let(:storage_creator) { create(:admin) }

  let(:host_response_body) { '{"data": "that you want to return"}' }
  let(:host_response_code) { '404' }
  let(:host_response_message) { 'OK' }
  let(:host_response_major_version) { 23 }
  let(:host_response_body) do
    %{
      {
        "ocs": {
          "data": {
            "version": {
              "major": #{host_response_major_version},
              "minor": 0,
              "micro": 0,
              "string": "23.0.0",
              "edition": "",
              "extendedSupport": false
            }
          }
        }
      }
    }
  end

  before do
    unless storage_host.nil?
      stub_request(:get,
                   File.join(storage_host.sub("https://", ""),
                             '/ocs/v2.php/cloud/capabilities'))
    end
      # to_return(
      #   status: host_response_code,
      #   body: host_response_body
      # )
  end

  it_behaves_like 'contract is valid for active admins and invalid for regular users'

  describe 'validations' do
    let(:current_user) { build_stubbed :admin }


    context 'when all attributes are valid' do
      it_behaves_like 'contract is valid'
    end

    context 'when name is invalid' do
      context 'as it is too long' do
        let(:storage_name) { 'X' * 257 }

        it_behaves_like 'contract is invalid'
      end

      context 'as it is empty' do
        let(:storage_name) { ''}

        it_behaves_like 'contract is invalid'
      end

      context 'as it is not unique' do
        before do
          ::Storages::Storage.create(name: storage_name,
                                     provider_type: storage_provider_type,
                                     host: storage_host,
                                     creator: storage_creator)
        end

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

      context 'as host is nil' do
        let(:storage_host) { nil }

        it_behaves_like 'contract is invalid'
      end
      #
      # context 'when provider_type is nextcloud' do
      #   context 'with host not reachable' do
      #
      #   end
      # end
    end
  end
end
