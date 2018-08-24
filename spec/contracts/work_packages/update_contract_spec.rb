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

require 'spec_helper'
require 'contracts/work_packages/shared_base_contract'

describe WorkPackages::UpdateContract do
  let(:project) { FactoryBot.create(:project, is_public: false) }
  let(:work_package) { FactoryBot.create(:work_package, project: project) }
  let(:user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i[view_work_packages edit_work_packages] }

  subject(:contract) { described_class.new(work_package, user) }

  it_behaves_like 'work package contract' do
    let(:work_package) { FactoryBot.build_stubbed(:work_package) }
  end

  describe 'lock_version' do
    context 'no lock_version present' do
      before do
        work_package.lock_version = nil
        contract.validate
      end

      it { expect(contract.errors.symbols_for(:base)).to include(:error_conflict) }
    end

    context 'lock_version changed' do
      before do
        work_package.lock_version += 1
        contract.validate
      end

      it { expect(contract.errors.symbols_for(:base)).to include(:error_conflict) }
    end

    context 'lock_version present and unchanged' do
      before do
        contract.validate
      end

      it { expect(contract.errors.symbols_for(:base)).not_to include(:error_conflict) }
    end
  end

  describe 'authorization' do
    let(:attributes) { {} }
    before do
      work_package.attributes = attributes
      contract.validate
    end

    context 'full access' do
      it { expect(contract.errors).to be_empty }
    end

    context 'no read access' do
      let(:permissions) { [:edit_work_packages] }

      it { expect(contract.errors.symbols_for(:base)).to include(:error_not_found) }
    end

    context 'no write access' do
      let(:permissions) { [:view_work_packages] }

      it { expect(contract.errors.symbols_for(:base)).to include(:error_unauthorized) }
    end

    context 'only comment permission' do
      let(:permissions) { %i[view_work_packages add_work_package_notes] }

      context 'when only adding a journal' do
        let(:attributes) { { journal_notes: 'some notes' } }

        it 'is valid' do
          expect(contract.errors).to be_empty
        end
      end

      context 'when changing more than a journal' do
        let(:attributes) { { journal_notes: 'some notes', subject: 'blubs' } }

        it 'is invalid' do
          expect(contract.errors.symbols_for(:base)).to include(:error_unauthorized)
        end
      end
    end
  end

  describe 'project_id' do
    let(:target_project) { FactoryBot.create(:project) }
    let(:target_permissions) { [:move_work_packages] }

    before do
      FactoryBot.create :member,
                        user: user,
                        project: target_project,
                        roles: [FactoryBot.create(:role, permissions: target_permissions)]

      work_package.project = target_project

      contract.validate
    end

    context 'if the user has the permissions' do
      it('is valid') { expect(contract.errors).to be_empty }
    end

    context 'if the user lacks the permissions' do
      let(:target_permissions) { [] }
      it 'is invalid' do
        expect(contract.errors.symbols_for(:project)).to match_array([:error_unauthorized])
      end
    end
  end

  describe 'parent_id' do
    let(:parent) { FactoryBot.create(:work_package) }

    before do
      work_package.parent_id = parent.id
      contract.validate
    end

    context 'if the user has only edit permissions' do
      it { expect(contract.errors.symbols_for(:base)).to include(:error_unauthorized) }
    end

    context 'if the user has edit and subtasks permissions' do
      let(:permissions) { %i[edit_work_packages view_work_packages manage_subtasks] }

      it('is valid') do
        expect(contract.errors).to be_empty
      end

      describe 'invalid lock version' do
        before do
          work_package.lock_version = 9999
          contract.validate
        end

        it { expect(contract.errors.symbols_for(:base)).to include(:error_conflict) }
      end
    end

    context 'no write access' do
      let(:permissions) { [:view_work_packages] }

      it { expect(contract.errors.symbols_for(:base)).to include(:error_unauthorized) }
    end

    context 'with manage_subtasks permission' do
      let(:permissions) { %i[view_work_packages manage_subtasks] }

      it('is valid') do
        expect(contract.errors).to be_empty
      end

      describe 'changing more than the parent_id' do
        before do
          work_package.subject = 'Foobar!'
          contract.validate
        end

        it { expect(contract.errors.symbols_for(:base)).to include(:error_unauthorized) }
      end
    end
  end
end
