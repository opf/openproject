#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

describe Query do
  let(:query) { build(:query) }

  describe 'available_columns' do
    context 'with work_package_done_ratio NOT disabled' do
      it 'should include the done_ratio column' do
        query.available_columns.find {|column| column.name == :done_ratio}.should be_true
      end
    end

    context 'with work_package_done_ratio disabled' do
      before do
        Setting.stub(:work_package_done_ratio).and_return('disabled')
      end

      it 'should NOT include the done_ratio column' do
        query.available_columns.find {|column| column.name == :done_ratio}.should be_nil
      end
    end

  end

  describe '#valid?' do
    context 'with a missing value' do
      before do
        query.add_filter('due_date', 't-', [''])
      end

      it 'is not valid and creates an error' do
        expect(query.valid?).to be_false
        expect(query.errors[:base].first).to include(I18n.t('activerecord.errors.messages.blank'))
      end
    end

    context 'when filters are blank' do
      let(:status) { create :status }
      let(:query) { build(:query).tap {|q| q.filters = []} }

      it 'is not valid and creates an error' do
        expect(query.valid?).to be_false
        expect(query.errors[:filters]).to include(I18n.t('activerecord.errors.messages.blank'))
      end
    end
  end

  let!(:project) { create :project }
  let(:role) { create(:role, permissions: [:view_work_packages]) }
  let(:project_member) { create(:user, member_in_project: project, member_through_role: role) }

  let(:query) { create :query, project: project, name: '_', user: project_member }
  let(:field) { 'cf_1' }
  let(:values) { [''] }
  let(:filter) { build :work_packages_filter, field: field, operator: operator, values: values }

  describe '#results' do
    let!(:work_package) { create :work_package,
                            project: project }

    before { User.stub(:current).and_return(project_member) }
    before { query.filters = [filter] }

    describe 'work_packages' do
      let(:resulting_work_packages) { query.results.work_packages }
      subject { resulting_work_packages }

      # operator 'none'
      context "when it has a filter of type integer with 'none' operator" do
        let!(:work_package_with_estimation) { create :work_package,
                                                      project: project,
                                                      estimated_hours: 4 }

        let(:field) { 'estimated_hours' }
        let(:operator) { '!*' }

        it { should_not include work_package_with_estimation }
      end

      # operator 'greater than'
      context "when it searches for work packages with done ration greater than x" do
        let(:done_ratio) { 50 }
        let(:field) { 'done_ratio' }
        let(:operator) { '>=' }
        let(:values) { [done_ratio - 10] }

        let!(:started_work_package) { create :work_package,
                                              project: project,
                                              start_date: 2.days.ago,
                                              done_ratio: done_ratio }

        it { should include started_work_package }
        it { should_not include work_package }
      end

      # operator 'in more than'
      context "when it searches for work packages with done ration greater than x" do
        let(:due_in_days) { 7 }
        let(:due_date) { Date.today + due_in_days.days }
        let(:field) { 'due_date' }
        let(:operator) { '>t+' }
        let(:values) { [due_in_days] }

        let!(:work_package_due_within_period) { create :work_package,
                                                        project: project,
                                                        due_date: due_date - 1.day }

        let!(:work_package_due_after_period)  { create :work_package,
                                                        project: project,
                                                        due_date: due_date + 1.day }

        it { should include work_package_due_after_period}
        it { should_not include work_package_due_within_period}
        it { should_not include work_package}
      end

    end
  end

  describe '#statement' do
    before { query.filters = [filter] }
    subject { query.statement }

    shared_examples :valid_sql do
      example do
        expect { WorkPackage.find :all,
                  include: [ :assigned_to, :status, :type, :project, :priority ],
                  conditions: query.statement }.not_to raise_error
      end
    end

    shared_context 'the fixed version filter is set' do
      before { query.filters << build(:work_packages_filter, field: 'fixed_version_id', operator: operator, values: ['']) }
    end

    context "when it has a filter with '*' operator" do
      let(:operator) { '*' }

      it_behaves_like :valid_sql

      it { should include "#{CustomValue.table_name}.value IS NOT NULL AND #{CustomValue.table_name}.value <> ''"}

      context 'and a filter for fixed_version is applied simultaneously' do
        include_context 'the fixed version filter is set'

        it_behaves_like :valid_sql

        it { should include "#{CustomValue.table_name}.value IS NOT NULL AND #{CustomValue.table_name}.value <> ''"}
        it { should include "#{WorkPackage.table_name}.fixed_version_id IS NOT NULL"}
      end
    end

    context "when it has a filter with 'none' operator" do
      let(:operator) { '!*' }

      it_behaves_like :valid_sql

      it { should include "#{CustomValue.table_name}.value IS NULL OR #{CustomValue.table_name}.value = ''"}

      context 'and a filter for fixed_version is applied simultaneously' do
        include_context 'the fixed version filter is set'

        it_behaves_like :valid_sql

        it { should include "#{CustomValue.table_name}.value IS NULL OR #{CustomValue.table_name}.value = ''"}
        it { should include "#{WorkPackage.table_name}.fixed_version_id IS NULL"}
      end
    end

    context "when it has a filter of type integer with 'none' operator" do
      let(:field) { 'estimated_hours' }
      let(:operator) { '!*' }

      it_behaves_like :valid_sql

      it { should include "#{WorkPackage.table_name}.#{field} IS NULL"}

      context 'and a filter for fixed_version is applied simultaneously' do
        include_context 'the fixed version filter is set'

        it_behaves_like :valid_sql

        it { should include "#{WorkPackage.table_name}.#{field} IS NULL" }
        it { should include "#{WorkPackage.table_name}.fixed_version_id IS NULL"}
      end
    end

    context "when it has a 'member_of_group' filter" do

    end
  end

end
