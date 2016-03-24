#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

shared_examples_for 'work package contract' do
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:other_user) { FactoryGirl.build_stubbed(:user) }
  let(:policy) { double(WorkPackagePolicy, allowed?: true) }

  subject(:contract) { described_class.new(work_package, user) }

  let(:validated_contract) {
    contract = subject
    contract.validate
    contract
  }

  before do
    allow(WorkPackagePolicy)
      .to receive(:new)
      .and_return(policy)
  end

  shared_examples_for 'has no error on' do |property|
    it property do
      expect(validated_contract.errors[property]).to be_empty
    end
  end

  describe 'assigned_to_id' do
    let(:assignee_members) { double('assignee_members') }

    before do
      allow(work_package)
        .to receive(:project)
        .and_return(project)

      allow(project)
        .to receive(:possible_assignee_members)
        .and_return(assignee_members)

      allow(assignee_members)
        .to receive(:exists?)
        .with(user_id: other_user.id)
        .and_return true

      work_package.assigned_to = other_user
    end

    context 'if the assigned user is a possible assignee' do
      it_behaves_like 'has no error on', :assignee
    end

    context 'if the assigned user is not a possible assignee' do
      before do
        allow(assignee_members)
          .to receive(:exists?)
          .with(user_id: other_user.id)
          .and_return false
      end

      it 'is not a valid assignee' do
        error = I18n.t('api_v3.errors.validation.invalid_user_assigned_to_work_package',
                       property: I18n.t('attributes.assignee'))
        expect(validated_contract.errors[:assignee]).to match_array [error]
      end
    end

    context 'if the project is not set' do
      before do
        allow(work_package)
          .to receive(:project)
          .and_return(nil)
      end

      it_behaves_like 'has no error on', :assignee
    end
  end

  describe 'responsible_id' do
    let(:responsible_members) { double('responsible_members') }

    before do
      allow(work_package)
        .to receive(:project)
        .and_return(project)

      allow(project)
        .to receive(:possible_responsible_members)
        .and_return(responsible_members)

      allow(responsible_members)
        .to receive(:exists?)
        .with(user_id: other_user.id)
        .and_return true

      work_package.responsible = other_user
    end

    context 'if the responsible user is a possible responsible' do
      it_behaves_like 'has no error on', :responsible
    end

    context 'if the assigned user is not a possible responsible' do
      before do
        allow(responsible_members)
          .to receive(:exists?)
          .with(user_id: other_user.id)
          .and_return false
      end

      it 'is not a valid responsible' do
        error = I18n.t('api_v3.errors.validation.invalid_user_assigned_to_work_package',
                       property: I18n.t('attributes.responsible'))
        expect(validated_contract.errors[:responsible]).to match_array [error]
      end
    end

    context 'if the project is not set' do
      before do
        allow(work_package)
          .to receive(:project)
          .and_return(nil)
      end

      it_behaves_like 'has no error on', :responsible
    end
  end
end
