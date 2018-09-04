#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe Query, type: :model do
  let(:query) { FactoryBot.build(:query) }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:relation_columns_allowed) { true }

  before do
    allow(EnterpriseToken)
      .to receive(:allows_to?)
      .with(:work_package_query_relation_columns)
      .and_return(relation_columns_allowed)
  end

  describe '.new_default' do
    it 'set the default sortation' do
      query = Query.new_default

      expect(query.sort_criteria)
        .to match_array([['parent', 'asc']])
    end

    it 'does not use the default sortation if an order is provided' do
      query = Query.new_default(sort_criteria: [['id', 'asc']])

      expect(query.sort_criteria)
        .to match_array([['id', 'asc']])
    end
  end

  describe 'timeline' do
    it 'has a property for timeline visible' do
      expect(query.timeline_visible).to be_falsey
      query.timeline_visible = true
      expect(query.timeline_visible).to be_truthy
    end

    it 'validates the timeline labels hash keys' do
      expect(query.timeline_labels).to eq({})
      expect(query).to be_valid

      query.timeline_labels = { 'left' => 'foobar', 'xyz' => 'bar' }
      expect(query).not_to be_valid

      query.timeline_labels = { 'left' => 'foobar', 'right' => 'bar', 'farRight' => 'blub' }
      expect(query).to be_valid
    end
  end

  describe 'highlighting' do
    it 'accepts valid values' do
      %w(inline none status priority).each do |val|
        query.highlighting_mode = val
        expect(query).to be_valid
        expect(query.highlighting_mode).to eq(val.to_sym)
      end
    end

    it 'accepts non-present values' do
      query.highlighting_mode = nil
      expect(query).to be_valid

      query.highlighting_mode = ''
      expect(query).to be_valid
    end

    it 'rejects invalid values' do
      query.highlighting_mode = 'bogus'
      expect(query).not_to be_valid
    end
  end

  describe 'hierarchies' do
    it 'is enabled in default queries' do
      query = Query.new_default
      expect(query.show_hierarchies).to be_truthy
      query.show_hierarchies = false
      expect(query.show_hierarchies).to be_falsey
    end

    it 'is mutually exclusive with group_by' do
      query = Query.new_default
      expect(query.show_hierarchies).to be_truthy
      query.group_by = :assignee

      expect(query.save).to be_falsey
      expect(query).not_to be_valid
      expect(query.errors[:show_hierarchies].first)
        .to include(I18n.t('activerecord.errors.models.query.group_by_hierarchies_exclusive', group_by: 'assignee'))
    end
  end

  describe '#available_columns' do
    context 'with work_package_done_ratio NOT disabled' do
      it 'should include the done_ratio column' do
        expect(query.available_columns.map(&:name)).to include :done_ratio
      end
    end

    context 'with work_package_done_ratio disabled' do
      before do
        allow(WorkPackage).to receive(:done_ratio_disabled?).and_return(true)
      end

      it 'should NOT include the done_ratio column' do
        expect(query.available_columns.map(&:name)).not_to include :done_ratio
      end
    end

    context 'results caching' do
      let(:project2) { FactoryBot.build_stubbed(:project) }

      it 'does not call the db twice' do
        query.project = project

        query.available_columns

        expect(project)
          .not_to receive(:all_work_package_custom_fields)

        expect(project)
          .not_to receive(:types)

        query.available_columns
      end

      it 'does call the db if the project changes' do
        query.project = project

        query.available_columns

        query.project = project2

        expect(project2)
          .to receive(:all_work_package_custom_fields)
          .and_return []

        expect(project2)
          .to receive(:types)
          .and_return []

        query.available_columns
      end

      it 'does call the db if the project changes to nil' do
        query.project = project

        query.available_columns

        query.project = nil

        expect(WorkPackageCustomField)
          .to receive(:all)
          .and_return []

        expect(Type)
          .to receive(:all)
          .and_return []

        query.available_columns
      end
    end

    context 'relation_to_type columns' do
      let(:type_in_project) do
        type = FactoryBot.create(:type)
        project.types << type

        type
      end

      let(:type_not_in_project) do
        FactoryBot.create(:type)
      end

      before do
        type_in_project
        type_not_in_project
      end

      context 'in project' do
        before do
          query.project = project
        end

        it 'includes the relation columns for project types' do
          expect(query.available_columns.map(&:name)).to include :"relations_to_type_#{type_in_project.id}"
        end

        it 'does not include the relation columns for types not in project' do
          expect(query.available_columns.map(&:name)).not_to include :"relations_to_type_#{type_not_in_project.id}"
        end

        context 'with the enterprise token disallowing relation columns' do
          let(:relation_columns_allowed) { false }

          it 'excludes the relation columns' do
            expect(query.available_columns.map(&:name)).not_to include :"relations_to_type_#{type_in_project.id}"
          end
        end
      end

      context 'global' do
        before do
          query.project = nil
        end

        it 'includes the relation columns for all types' do
          expect(query.available_columns.map(&:name)).to include(:"relations_to_type_#{type_in_project.id}",
                                                                 :"relations_to_type_#{type_not_in_project.id}")
        end

        context 'with the enterprise token disallowing relation columns' do
          let(:relation_columns_allowed) { false }

          it 'excludes the relation columns' do
            expect(query.available_columns.map(&:name)).not_to include(:"relations_to_type_#{type_in_project.id}",
                                                                       :"relations_to_type_#{type_not_in_project.id}")
          end
        end
      end
    end

    context 'relation_of_type columns' do
      before do
        stub_const('Relation::TYPES',
                   relation1: { name: :label_relates_to, sym_name: :label_relates_to, order: 1, sym: :relation1 },
                   relation2: { name: :label_duplicates, sym_name: :label_duplicated_by, order: 2, sym: :relation2 })
      end

      it 'includes the relation columns for every relation type' do
        expect(query.available_columns.map(&:name)).to include(:relations_of_type_relation1,
                                                               :relations_of_type_relation2)
      end

      context 'with the enterprise token disallowing relation columns' do
        let(:relation_columns_allowed) { false }

        it 'excludes the relation columns' do
          expect(query.available_columns.map(&:name)).not_to include(:relations_of_type_relation1,
                                                                     :relations_of_type_relation2)
        end
      end
    end
  end

  describe '.available_columns' do
    let(:custom_field) { FactoryBot.create(:list_wp_custom_field) }
    let(:type) { FactoryBot.create(:type) }

    before do
      stub_const('Relation::TYPES',
                 relation1: { name: :label_relates_to, sym_name: :label_relates_to, order: 1, sym: :relation1 },
                 relation2: { name: :label_duplicates, sym_name: :label_duplicated_by, order: 2, sym: :relation2 })
    end

    context 'with the enterprise token allowing relation columns' do
      it 'has all static columns, cf columns and relation columns' do
        expected_columns = %i(id project assigned_to author
                              category created_at due_date estimated_hours
                              parent done_ratio priority responsible
                              spent_hours start_date status subject type
                              updated_at fixed_version) +
                           [:"cf_#{custom_field.id}"] +
                           [:"relations_to_type_#{type.id}"] +
                           %i(relations_of_type_relation1 relations_of_type_relation2)

        expect(Query.available_columns.map(&:name)).to include *expected_columns
      end
    end

    context 'with the enterprise token disallowing relation columns' do
      let(:relation_columns_allowed) { false }

      it 'has all static columns, cf columns but no relation columns' do
        expected_columns = %i(id project assigned_to author
                              category created_at due_date estimated_hours
                              parent done_ratio priority responsible
                              spent_hours start_date status subject type
                              updated_at fixed_version) +
                           [:"cf_#{custom_field.id}"]

        unexpected_columns = [:"relations_to_type_#{type.id}"] +
                             %i(relations_of_type_relation1 relations_of_type_relation2)

        expect(Query.available_columns.map(&:name)).to include *expected_columns
        expect(Query.available_columns.map(&:name)).not_to include *unexpected_columns
      end
    end
  end

  describe '#valid?' do
    it 'should not be valid without a name' do
      query.name = ''
      expect(query.save).to be_falsey
      expect(query.errors[:name].first).to include(I18n.t('activerecord.errors.messages.blank'))
    end

    context 'with a missing value and an operator that requires values' do
      before do
        query.add_filter('due_date', 't-', [''])
      end

      it 'is not valid and creates an error' do
        expect(query.valid?).to be_falsey
        expect(query.errors[:base].first).to include(I18n.t('activerecord.errors.messages.blank'))
      end
    end

    context 'when filters are blank' do
      let(:status) { FactoryBot.create :status }
      let(:query) { FactoryBot.build(:query).tap { |q| q.filters = [] } }

      it 'is valid' do
        expect(query.valid?).to be_truthy
      end
    end

    context 'with a missing value for a custom field' do
      let(:custom_field) do
        FactoryBot.create :text_issue_custom_field, is_filter: true, is_for_all: true
      end

      before do
        query.add_filter('cf_' + custom_field.id.to_s, '=', [''])
      end

      it 'should have the name of the custom field in the error message' do
        expect(query).to_not be_valid
        expect(query.errors.messages[:base].to_s).to include(custom_field.name)
      end
    end

    context 'with a filter for a non existing custom field' do
      before do
        query.add_filter('cf_0', '=', ['1'])
      end

      it 'is not valid' do
        expect(query.valid?).to be_falsey
      end
    end
  end

  describe '#valid_subset!' do
    let(:valid_status) { FactoryBot.build_stubbed(:status) }

    context 'filters' do
      before do
        allow(Status)
          .to receive(:all)
          .and_return([valid_status])

        allow(Status)
          .to receive(:exists?)
          .and_return(true)

        query.filters.clear
        query.add_filter('status_id', '=', values)

        query.valid_subset!
      end

      context 'for a status filter having valid and invalid values' do
        let(:values) { [valid_status.id.to_s, '99999'] }

        it 'leaves the filter' do
          expect(query.filters.length).to eq 1
        end

        it 'leaves only the valid value' do
          expect(query.filters[0].values)
            .to match_array [valid_status.id.to_s]
        end
      end

      context 'for a status filter having only invalid values' do
        let(:values) { ['99999'] }

        it 'removes the filter' do
          expect(query.filters.length).to eq 0
        end
      end

      context 'for an unavailable filter' do
        let(:values) { [valid_status.id.to_s] }
        before do
          query.add_filter('cf_0815', '=', ['1'])

          query.valid_subset!
        end

        it 'removes the invalid filter' do
          expect(query.filters.length).to eq 1
          expect(query.filters[0].name).to eq :status_id
        end
      end
    end

    context 'group_by' do
      before do
        query.group_by = group_by
      end

      context 'valid' do
        let(:group_by) { 'project' }

        it 'leaves the value untouched' do
          query.valid_subset!

          expect(query.group_by).to eql group_by
        end
      end

      context 'invalid' do
        let(:group_by) { 'cf_0815' }

        it 'removes the group by' do
          query.valid_subset!

          expect(query.group_by).to be_nil
        end
      end
    end

    context 'sort_criteria' do
      before do
        query.sort_criteria = sort_by
      end

      context 'valid' do
        let(:sort_by) { [['project', 'desc']] }

        it 'leaves the value untouched' do
          query.valid_subset!

          expect(query.sort_criteria).to eql sort_by
        end
      end

      context 'invalid' do
        let(:sort_by) { [['cf_0815', 'desc']] }

        it 'removes the sorting' do
          query.valid_subset!

          expect(query.sort_criteria).to be_empty
        end
      end

      context 'partially invalid' do
        let(:sort_by) { [['cf_0815', 'desc'], ['project', 'desc']] }

        it 'removes the offending values from sort' do
          query.valid_subset!

          expect(query.sort_criteria).to match_array [['project', 'desc']]
        end
      end
    end

    context 'columns' do
      before do
        query.column_names = columns
      end

      context 'valid' do
        let(:columns) { %i(status project) }

        it 'leaves the values untouched' do
          query.valid_subset!

          expect(query.column_names)
            .to match_array columns
        end
      end

      context 'invalid' do
        let(:columns) { %i(bogus cf_0815) }

        it 'removes the values' do
          query.valid_subset!

          expect(query.column_names)
            .to be_empty
        end
      end

      context 'partially invalid' do
        let(:columns) { %i(status cf_0815) }

        it 'removes the offending values' do
          query.valid_subset!

          expect(query.column_names)
            .to match_array [:status]
        end
      end
    end
  end

  describe '#filter_for' do
    context 'for a status_id filter' do
      before do
        allow(Status)
          .to receive(:exists?)
          .and_return(true)
      end

      subject { query.filter_for('status_id') }

      it 'exists' do
        is_expected.to_not be_nil
      end

      it 'has the context set' do
        expect(subject.context).to eql query
      end

      it 'reuses an existing filter' do
        expect(subject.object_id).to eql query.filter_for('status_id').object_id
      end
    end
  end

  describe 'filters after deserialization' do
    it 'sets the context (project) on deserialization' do
      query.save!

      query.reload
      query.filters.each do |filter|
        expect(filter.context).to eql(query)
      end
    end
  end
end
