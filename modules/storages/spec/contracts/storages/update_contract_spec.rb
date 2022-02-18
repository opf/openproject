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
require 'contracts/shared/model_contract_shared_context'
require_relative 'shared_contract_examples'

describe ::Storages::Storages::UpdateContract do
  include_context 'ModelContract shared context'

  it_behaves_like 'storage contract' do
    let(:storage) do
      build_stubbed(:storage,
                    creator: current_user,
                    host: 'https://host1.example.com',
                    name: 'Storage 1',
                    provider_type: 'nextcloud').tap do |storage|
        if storage_name == storage.name
          # trigger at least one change per default
          storage.name += " (DEFAULT UPDATED)"
        else
          storage.name = storage_name
        end
        storage.host = storage_host
        storage.provider_type = storage_provider_type
        storage.creator = storage_creator
      end
    end
    let(:contract) { described_class.new(storage, current_user) }
  end
end
