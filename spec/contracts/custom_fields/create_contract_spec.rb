#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe CustomFields::CreateContract do
  let(:cf) { FactoryBot.build :project_custom_field }
  let(:contract) do
    described_class.new(cf, current_user, options: { changed_by_system: [] })
  end

  describe 'as admin' do
    let(:current_user) { FactoryBot.build_stubbed :admin }

    it 'validates the contract' do
      expect(contract.validate).to eq(true)
    end
  end

  describe 'as regular user' do
    let(:current_user) { FactoryBot.build_stubbed :user }

    it 'invalidates the contract' do
      expect(contract.validate).to eq(false)
      expect(contract.errors.symbols_for(:base))
        .to match_array [:error_unauthorized]
    end
  end
end
