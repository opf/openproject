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
require_relative './shared_contract_examples'

describe Projects::BaseContract do
  let(:project) { Project.new(name: 'Foo', identifier: 'foo', templated: false) }
  let(:contract) { described_class.new(project, current_user) }
  subject { contract.validate }

  describe 'templated attribute' do
    before do
      # Assume the user may manage the project
      allow(contract)
        .to(receive(:validate_user_allowed_to_manage))
        .and_return true

      # Assume templated attribute got changed
      project.templated = true
      expect(project.templated_changed?).to eq true
    end

    context 'as admin' do
      let(:current_user) { FactoryBot.build_stubbed :admin }

      it 'validates the contract' do
        expect(subject).to eq true
      end
    end

    context 'as regular user' do
      let(:current_user) { FactoryBot.build_stubbed :user }

      it 'returns an error on validation' do
        expect(subject).to eq false
        expect(contract.errors.symbols_for(:templated))
          .to match_array [:error_unauthorized]
      end
    end
  end
end
