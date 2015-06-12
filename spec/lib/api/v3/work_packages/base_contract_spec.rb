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

require 'spec_helper'

describe ::API::V3::WorkPackages::BaseContract do
  let(:work_package) do
    FactoryGirl.create(:work_package,
                       done_ratio: 50,
                       estimated_hours: 6.0,
                       project: project)
  end
  let(:member) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let (:project) { FactoryGirl.create(:project) }
  let(:current_user) { member }
  let(:permissions) {
    [
      :view_work_packages,
      :view_work_package_watchers,
      :edit_work_packages,
      :add_work_package_watchers,
      :delete_work_package_watchers,
      :manage_work_package_relations,
      :add_work_package_notes
    ]
  }
  let(:role) { FactoryGirl.create :role, permissions: permissions }
  let(:changed_values) { [] }

  subject(:contract) { described_class.new(work_package, current_user) }

  before do
    allow(work_package).to receive(:changed).and_return(changed_values)
  end

  shared_examples 'a parent unwritable property' do |attribute|
    context 'is no parent' do
      before do
        contract.validate
      end

      context 'has not changed' do
        it('is valid') { expect(contract.errors.empty?).to be true }
      end

      context 'has changed' do
        let(:changed_values) { [attribute] }

        it('is valid') { expect(contract.errors.empty?).to be true }
      end
    end

    context 'is a parent' do
      before do
        child
        work_package.reload
        contract.validate
      end
      let(:child) do
        FactoryGirl.create(:work_package, parent_id: work_package.id, project: project)
      end

      context 'has not changed' do
        it('is valid') { expect(contract.errors.empty?).to be true }
      end

      context 'has changed' do
        let(:changed_values) { [attribute] }

        it('is invalid') do
          expect(contract.errors[:error_readonly]).to match_array(changed_values)
        end
      end
    end
  end

  describe 'estimated hours' do
    it_behaves_like 'a parent unwritable property', 'estimated_hours'
  end

  describe 'start date' do
    it_behaves_like 'a parent unwritable property', 'start_date'
  end

  describe 'due date' do
    it_behaves_like 'a parent unwritable property', 'due_date'
  end

  describe 'percentage done' do
    context 'has not changed' do
      before do
        contract.validate
      end

      it('is valid') { expect(contract.errors.empty?).to be true }
    end

    context 'has changed' do
      before do
        contract.validate
      end

      let(:changed_values) { ['done_ratio'] }

      it('is valid') { expect(contract.errors.empty?).to be true }

      context 'is parent' do
        before do
          child
          work_package.reload
          contract.validate
        end

        let(:child) do
          FactoryGirl.create(:work_package, parent_id: work_package.id, project: project)
        end

        it('is invalid') do
          expect(contract.errors[:error_readonly]).to match_array(changed_values)
        end
      end

      context 'done ratio inferred by status' do
        before do
          allow(Setting).to receive(:work_package_done_ratio).and_return('status')
          contract.validate
        end

        it('is invalid') do
          expect(contract.errors[:error_readonly]).to match_array(changed_values)
        end
      end

      context 'done ratio disabled' do
        before do
          allow(Setting).to receive(:work_package_done_ratio).and_return('disabled')
          contract.validate
        end

        it('is invalid') do
          expect(contract.errors[:error_readonly]).to match_array(changed_values)
        end
      end
    end
  end
end
