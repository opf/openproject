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

describe Queries::WorkPackages::Filter, type: :model do
  describe '#type' do

    describe 'validations' do
      subject { filter }

      let(:filter) { FactoryGirl.build :work_packages_filter }

      context 'when the operator does not require values' do
        let(:filter) { FactoryGirl.build :work_packages_filter, field: :status_id, operator: '*', values: [] }

        it 'is valid if no values are given' do
          expect(filter).to be_valid
        end
      end

      context 'when the operator requires values' do
        let(:filter) { FactoryGirl.build :work_packages_filter, field: :done_ratio, operator: '>=', values: [] }

        context 'and no value is given' do
          it { is_expected.not_to be_valid }
        end

        context 'and only an empty string is given as value' do
          let(:filter) { FactoryGirl.build :work_packages_filter, field: :due_date, operator: 't-', values: [''] }

          it { is_expected.not_to be_valid }
        end

        context 'and values are given' do
          before { filter.values = [5] }

          it { is_expected.to be_valid }
        end
      end

      context 'when it is of type integer' do
        let(:filter) { FactoryGirl.build :work_packages_filter, field: :done_ratio, operator: '>=', values: [] }

        before { filter.field = 'done_ratio' }

        context 'and the filter values is an integer' do
          before { filter.values = [1, '12', 123] }

          it { is_expected.to be_valid }
        end

        context 'and the filter values is not an integer' do
          before { filter.values == [1, 'asdf'] }

          it { is_expected.not_to be_valid }

          context 'and the operator is *' do
            before { filter.operator = '*' }

            it { is_expected.to be_valid }
          end
        end
      end

      context 'when it if of type date or date_past' do
        let(:filter) { FactoryGirl.build :work_packages_filter, field: :created_at }

        context "and the operator is 't' (today)" do
          before { filter.operator = 't' }

          it { is_expected.to be_valid }
        end

        context "and the operator is 'w' (this week)" do
          before { filter.operator = 'w' }

          it { is_expected.to be_valid }
        end

        context 'and the operator compares the current day' do
          before { filter.operator = '>t-' }

          context 'and the value is an integer' do
            before { filter.values = ['4'] }

            it { is_expected.to be_valid }
          end

          context 'and the value is not an integer' do
            before { filter.values = ['four'] }

            it { is_expected.not_to be_valid }
          end
        end
      end

      context 'when it is a work package filter' do
        let(:filter) { FactoryGirl.build :work_packages_filter }

        context 'and the field is whitelisted' do
          before { filter.field = :project_id }

          it { is_expected.to be_valid }
        end

        # this context tests the case when a new item is injected in
        # the filter_types_by_field hash afterwards
        # from within some plugins that patch Queries::WorkPackages::Filter
        context 'and the field is whitelisted afterwards' do
          before do
            filter.field = :some_new_key
            filter.class.add_filter_type_by_field('some_new_key', 'list')
          end

          it { is_expected.to be_valid }
        end

        context 'and the field is not whitelisted and no custom field key' do
          before { filter.field = :any_key }

          it { is_expected.not_to be_valid }
        end

        context 'and the field is a custom field starting with "cf"' do
          before { filter.field = :cf_any_key }

          it { is_expected.to be_valid }
        end
      end
    end
  end
end
