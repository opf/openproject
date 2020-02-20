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

describe Members::SetAttributesService, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:contract_class) do
    contract = double('contract_class')

    allow(contract)
      .to receive(:new)
      .with(member, user, options: { changed_by_system: [] })
      .and_return(contract_instance)

    contract
  end
  let(:contract_instance) do
    double('contract_instance', validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    double('contract_errors')
  end
  let(:member_valid) { true }
  let(:instance) do
    described_class.new(user: user,
                        model: member,
                        contract_class: contract_class)
  end
  let(:call_attributes) { {} }
  let(:member) do
    FactoryBot.build_stubbed(:member)
  end

  describe 'call' do
    let(:call_attributes) do
      {
        project_id: 5,
        user_id: 3
      }
    end

    before do
      allow(member)
        .to receive(:valid?)
        .and_return(member_valid)

      expect(contract_instance)
        .to receive(:validate)
        .and_return(contract_valid)
    end

    subject { instance.call(call_attributes) }

    it 'is successful' do
      expect(subject.success?).to be_truthy
    end

    it 'sets the attributes' do
      subject

      expect(member.attributes.slice(*member.changed).symbolize_keys)
        .to eql call_attributes
    end

    it 'does not persist the member' do
      expect(member)
        .not_to receive(:save)

      subject
    end

    context 'with changes to the roles do' do
      let(:first_role) { FactoryBot.build_stubbed(:role) }
      let(:second_role) { FactoryBot.build_stubbed(:role) }
      let(:third_role) { FactoryBot.build_stubbed(:role) }

      let(:call_attributes) do
        {
          role_ids: [second_role.id, third_role.id]
        }
      end

      context 'with a persisted record' do
        let(:member) do
          FactoryBot.build_stubbed(:member, roles: [first_role, second_role])
        end

        it 'adds the new role' do
          expect(subject.result.roles = [second_role, third_role])
        end
      end

      context 'with a new record' do
        let(:member) do
          Member.new
        end

        it 'adds the new role' do
          expect(subject.result.roles = [second_role, third_role])
        end
      end
    end
  end
end
