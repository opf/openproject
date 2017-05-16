#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WorkPackages::BaseContract do
  let(:work_package) do
    FactoryGirl.create(:work_package,
                       done_ratio: 50,
                       estimated_hours: 6.0,
                       project: project)
  end
  let(:member) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:project) { FactoryGirl.create(:project) }
  let(:current_user) { member }
  let(:permissions) do
    [
      :view_work_packages,
      :view_work_package_watchers,
      :edit_work_packages,
      :add_work_package_watchers,
      :delete_work_package_watchers,
      :manage_work_package_relations,
      :add_work_package_notes
    ]
  end
  let(:role) { FactoryGirl.create :role, permissions: permissions }
  let(:changed_values) { [] }

  subject(:contract) { described_class.new(work_package, current_user) }

  before do
    allow(work_package).to receive(:changed).and_return(changed_values.map(&:to_s))
  end

  shared_examples_for 'invalid if changed' do |attribute|
    before do
      contract.validate
    end

    context 'has changed' do
      let(:changed_values) { [attribute] }

      it('is invalid') do
        expect(contract.errors.symbols_for(attribute)).to match_array([:error_readonly])
      end
    end

    context 'has not changed' do
      let(:changed_values) { [] }

      it('is valid') { expect(contract.errors).to be_empty }
    end
  end

  shared_examples 'a parent unwritable property' do |attribute|
    context 'is no parent' do
      before do
        contract.validate
      end

      context 'has not changed' do
        let(:changed_values) { [] }

        it('is valid') { expect(contract.errors).to be_empty }
      end

      context 'has changed' do
        let(:changed_values) { [attribute] }

        it('is valid') { expect(contract.errors).to be_empty }
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
        let(:changed_values) { [] }

        it('is valid') { expect(contract.errors).to be_empty }
      end

      context 'has changed' do
        let(:changed_values) { [attribute] }

        it('is invalid (read only)') do
          expect(contract.errors.symbols_for(attribute)).to match_array([:error_readonly])
        end
      end
    end
  end

  describe 'estimated hours' do
    it_behaves_like 'a parent unwritable property', :estimated_hours
  end

  describe 'start date' do
    it_behaves_like 'a parent unwritable property', :start_date

    context 'before soonest start date of parent' do
      before do
        work_package.parent = FactoryGirl.build_stubbed(:work_package)
        allow(work_package.parent)
          .to receive(:soonest_start)
          .and_return(Date.today + 4.days)

        work_package.start_date = Date.today + 2.days
      end

      it 'notes the error' do
        contract.validate

        message = I18n.t('activerecord.errors.models.work_package.attributes.start_date.violates_parent_relationships',
                         soonest_start: Date.today + 4.days)

        expect(contract.errors[:start_date])
          .to match_array [message]
      end
    end
  end

  describe 'due date' do
    it_behaves_like 'a parent unwritable property', :due_date
  end

  describe 'percentage done' do
    it_behaves_like 'a parent unwritable property', :done_ratio

    context 'done ratio inferred by status' do
      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return('status')
      end

      it_behaves_like 'invalid if changed', :done_ratio
    end

    context 'done ratio disabled' do
      let(:changed_values) { [:done_ratio] }

      before do
        allow(Setting).to receive(:work_package_done_ratio).and_return('disabled')
      end

      it_behaves_like 'invalid if changed', :done_ratio
    end
  end
end
