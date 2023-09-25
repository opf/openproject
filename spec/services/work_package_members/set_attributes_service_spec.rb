# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

require 'spec_helper'

RSpec.describe WorkPackageMembers::SetAttributesService, type: :model do
  let(:user) { build_stubbed(:user) }
  let(:work_package) { build_stubbed(:work_package) }
  let(:member) do
    new_member
  end
  let(:new_member) { Member.new }
  let(:existing_member) { build_stubbed(:work_package_member) }

  let(:contract_class) do
    allow(WorkPackageMembers::CreateContract)
      .to receive(:new)
            .with(member, user, options: {})
            .and_return(contract_instance)

    WorkPackageMembers::CreateContract
  end
  let(:contract_instance) do
    instance_double(WorkPackageMembers::CreateContract, validate: contract_valid, errors: contract_errors)
  end
  let(:contract_valid) { true }
  let(:contract_errors) do
    instance_double(ActiveModel::Errors)
  end
  let(:instance) do
    described_class.new(user:,
                        model: member,
                        contract_class:)
  end

  describe 'call' do
    let(:call_attributes) do
      {
        user_id: 3,
        entity: work_package
      }
    end

    before do
      allow(contract_instance)
        .to receive(:validate)
              .and_return(contract_valid)

      allow(member)
        .to receive(:save)
              .and_return true
    end

    subject { instance.call(call_attributes) }

    it 'is successful' do
      expect(subject).to be_success
    end

    it 'does not persist the member' do
      subject

      expect(member)
        .not_to have_received(:save)
    end

    context 'for a new record' do
      it 'sets the attributes and also takes the project_id from the work package' do
        subject

        expect(member.attributes.slice(*member.changed).symbolize_keys)
          .to eql(user_id: 3, entity_id: work_package.id, entity_type: 'WorkPackage', project_id: work_package.project_id)
      end

      it 'marks the project_id to be changed by the system' do
        subject

        expect(member.changed_by_system)
          .to eql('project_id' => [nil, member.project_id])
      end
    end

    # Changing the entity should not really happen in reality but if it does, this is what happens.
    context 'for a persisted record' do
      let(:member) { existing_member }

      it 'sets the attributes and also takes the project_id from the work package' do
        subject

        expect(member.attributes.slice(*member.changed).symbolize_keys)
          .to eql(user_id: 3, entity_id: work_package.id, project_id: work_package.project_id)
      end

      it 'marks the project_id to be changed by the system' do
        subject

        expect(member.changed_by_system)
          .to eql('project_id' => [member.project_id_was, member.project_id])
      end
    end

    context 'if the contract is invalid' do
      let(:contract_valid) { false }

      it 'is unsuccessful' do
        expect(subject).not_to be_success
      end

      it 'returns the errors of the contract' do
        expect(subject.errors).to eql contract_errors
      end

      it 'does not persist the member' do
        subject

        expect(member)
          .not_to have_received(:save)
      end
    end
  end
end
