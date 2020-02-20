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

shared_context 'filter tests' do
  let(:context) { nil }
  let(:values) { ['bogus'] }
  let(:operator) { '=' }
  let(:instance_key) { described_class.key }
  let(:instance) do
    described_class.create!(name: instance_key, context: context, operator: operator, values: values)
  end
  let(:name) { model.human_attribute_name((instance_key || expected_class_key).to_s.gsub('_id', '')) }
  let(:model) { WorkPackage }
end

shared_examples_for 'basic query filter' do
  include_context 'filter tests'

  let(:context) { FactoryBot.build_stubbed(:query, project: project) }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:expected_class_key) { defined?(:class_key) ? class_key : raise('needs to be defined') }
  let(:type) { raise 'needs to be defined' }
  let(:human_name) { nil }

  describe '.key' do
    it 'is the defined key' do
      expect(described_class.key).to eql(expected_class_key)
    end
  end

  describe '#name' do
    it 'is the defined key' do
      expect(instance.name).to eql(instance_key || expected_class_key)
    end
  end

  describe '#type' do
    it 'is the defined filter type' do
      expect(instance.type).to eql(type)
    end
  end

  describe '#human_name' do
    it 'is the l10 name for the filter' do
      expect(instance.human_name).to eql(human_name.presence || name)
    end
  end
end

shared_examples_for 'list query filter' do |scope: true|
  include_context 'filter tests'
  let(:attribute) { raise "needs to be defined" }
  let(:type) { :list }

  if scope
    describe '#scope' do
      context 'for "="' do
        let(:operator) { '=' }
        let(:values) { valid_values }

        it 'is the same as handwriting the query' do
          expected = model.where(["#{model.table_name}.#{attribute} IN (?)", values])

          expect(instance.scope.to_sql).to eql expected.to_sql
        end
      end

      context 'for "!"' do
        let(:operator) { '!' }
        let(:values) { valid_values }

        it 'is the same as handwriting the query' do
          sql = "(#{model.table_name}.#{attribute} IS NULL
                 OR #{model.table_name}.#{attribute} NOT IN (?))".squish
          expected = model.where([sql, values])

          expect(instance.scope.to_sql).to eql expected.to_sql
        end
      end
    end
  end

  describe '#valid?' do
    let(:operator) { '=' }
    let(:values) { valid_values }

    it 'is valid' do
      expect(instance).to be_valid
    end

    context 'for an invalid operator' do
      let(:operator) { '*' }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end

    context 'for an invalid value' do
      let(:values) { ['inexistent'] }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end
  end
end

shared_examples_for 'list_optional query filter' do
  include_context 'filter tests'
  let(:attribute) { raise "needs to be defined" }
  let(:type) { :list_optional }
  let(:joins) { nil }
  let(:expected_base_scope) do
    if joins
      model.joins(joins)
    else
      model
    end
  end
  let(:expected_table_name) do
    joins || model.table_name
  end

  describe '#scope' do
    let(:values) { valid_values }

    context 'for "="' do
      let(:operator) { '=' }

      it 'is the same as handwriting the query' do
        expected = expected_base_scope
                   .where(["#{expected_table_name}.#{attribute} IN (?)", values])

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "!"' do
      let(:operator) { '!' }

      it 'is the same as handwriting the query' do
        sql = "(#{expected_table_name}.#{attribute} IS NULL
               OR #{expected_table_name}.#{attribute} NOT IN (?))".squish
        expected = expected_base_scope.where([sql, values])

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "*"' do
      let(:operator) { '*' }

      it 'is the same as handwriting the query' do
        sql = "#{expected_table_name}.#{attribute} IS NOT NULL"
        expected = expected_base_scope.where([sql])

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "!*"' do
      let(:operator) { '!*' }

      it 'is the same as handwriting the query' do
        sql = "#{expected_table_name}.#{attribute} IS NULL"
        expected = expected_base_scope.where([sql])
        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end
  end

  describe '#valid?' do
    let(:operator) { '=' }
    let(:values) { valid_values }

    it 'is valid' do
      expect(instance).to be_valid
    end

    context 'for an invalid operator' do
      let(:operator) { '~' }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end

    context 'for an invalid value' do
      let(:values) { ['inexistent'] }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end
  end
end

shared_examples_for 'list_optional group query filter' do
  include_context 'filter tests'
  describe '#scope' do
    let(:values) { valid_values }

    context 'for "="' do
      let(:operator) { '=' }

      it 'is the same as handwriting the query' do
        expected = model.where(["users.id IN (#{User.in_group(values).select(:id).to_sql})"])
        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "!"' do
      let(:operator) { '!' }

      it 'is the same as handwriting the query' do
        expected = model.where(["users.id NOT IN (#{User.in_group(values).select(:id).to_sql})"])
        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "*"' do
      let(:operator) { '*' }

      it 'is the same as handwriting the query' do
        expected = model.where(["users.id IN (#{User.within_group([]).select(:id).to_sql})"])
        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "!*"' do
      let(:operator) { '!*' }

      it 'is the same as handwriting the query' do
        expected = model.where(["users.id NOT IN (#{User.within_group([]).select(:id).to_sql})"])
        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end
  end

  describe '#valid?' do
    let(:operator) { '=' }
    let(:values) { valid_values }

    it 'is valid' do
      expect(instance).to be_valid
    end

    context 'for an invalid operator' do
      let(:operator) { '~' }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end

    context 'for an invalid value' do
      let(:values) { ['inexistent'] }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end
  end
end

shared_examples_for 'list_all query filter' do
  include_context 'filter tests'
  let(:attribute) { raise "needs to be defined" }
  let(:type) { :list_all }
  let(:joins) { nil }
  let(:expected_base_scope) do
    if joins
      model.joins(joins)
    else
      model
    end
  end
  let(:expected_table_name) do
    joins || model.table_name
  end

  describe '#scope' do
    let(:values) { valid_values }

    context 'for "="' do
      let(:operator) { '=' }

      it 'is the same as handwriting the query' do
        expected = expected_base_scope
                   .where(["#{expected_table_name}.#{attribute} IN (?)", values])

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "!"' do
      let(:operator) { '!' }

      it 'is the same as handwriting the query' do
        sql = "(#{expected_table_name}.#{attribute} IS NULL
               OR #{expected_table_name}.#{attribute} NOT IN (?))".squish
        expected = expected_base_scope.where([sql, values])

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "*"' do
      let(:operator) { '*' }

      it 'is the same as handwriting the query' do
        sql = "#{expected_table_name}.#{attribute} IS NOT NULL"
        expected = expected_base_scope.where([sql])

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end
  end

  describe '#valid?' do
    let(:operator) { '=' }
    let(:values) { valid_values }

    it 'is valid' do
      expect(instance).to be_valid
    end

    context 'for an invalid operator' do
      let(:operator) { '~' }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end

    context 'for an invalid value' do
      let(:values) { ['inexistent'] }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end
  end
end

shared_examples_for 'boolean query filter' do |scope: true|
  include_context 'filter tests'
  let(:attribute) { raise "needs to be defined" }
  let(:type) { :list }
  let(:joins) { nil }
  let(:expected_base_scope) do
    if joins
      model.joins(joins)
    else
      model
    end
  end
  let(:expected_table_name) do
    joins || model.table_name
  end

  let(:valid_values) { [OpenProject::Database::DB_VALUE_TRUE] }

  describe '#allowed_values' do
    it 'is list for a bool' do
      expect(instance.allowed_values)
        .to match_array [[I18n.t(:general_text_yes), OpenProject::Database::DB_VALUE_TRUE],
                         [I18n.t(:general_text_no), OpenProject::Database::DB_VALUE_FALSE]]
    end
  end

  if scope
    describe '#scope' do
      let(:values) { valid_values }

      context 'for "="' do
        let(:operator) { '=' }

        it 'is the same as handwriting the query' do
          expected = expected_base_scope
                     .where(["#{expected_table_name}.#{attribute} IN (?)", values])

          expect(instance.scope.to_sql).to eql expected.to_sql
        end
      end

      context 'for "!"' do
        let(:operator) { '!' }

        it 'is the same as handwriting the query' do
          sql = "#{expected_table_name}.#{attribute} IS NULL
                 OR #{expected_table_name}.#{attribute} IN (?)".squish
          expected = expected_base_scope.where([sql, [OpenProject::Database::DB_VALUE_FALSE]])

          expect(instance.scope.to_sql).to eql expected.to_sql
        end
      end
    end
  end

  describe '#valid?' do
    let(:operator) { '=' }
    let(:values) { valid_values }

    it 'is valid' do
      expect(instance).to be_valid
    end

    context 'for an invalid operator' do
      let(:operator) { '~' }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end

    context 'for an invalid value' do
      let(:values) { ['inexistent'] }

      it 'is invalid' do
        expect(instance).to be_invalid
      end
    end
  end
end

shared_examples_for 'non ar filter' do
  describe '#ar_object_filter?' do
    it 'is false' do
      expect(instance)
        .not_to be_ar_object_filter
    end
  end

  describe '#value_objects' do
    it 'is empty' do
      expect(instance.value_objects)
        .to be_empty
    end
  end
end

shared_examples_for 'filter by work package id' do
  include_context 'filter tests'

  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:query) do
    FactoryBot.build_stubbed(:query, project: project)
  end

  it_behaves_like 'basic query filter' do
    let(:type) { :list }

    before do
      instance.context = query
    end

    describe '#available?' do
      context 'within a project' do
        it 'is true if any work package exists and is visible' do
          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :exists?)
            .with(no_args)
            .with(project)
            .with(no_args)
            .and_return true

          expect(instance).to be_available
        end

        it 'is false if no work package exists/ is visible' do
          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :exists?)
            .with(no_args)
            .with(project)
            .with(no_args)
            .and_return false

          expect(instance).not_to be_available
        end
      end

      context 'outside of a project' do
        let(:project) { nil }

        it 'is true if any work package exists and is visible' do
          allow(WorkPackage)
            .to receive_message_chain(:visible, :exists?)
            .with(no_args)
            .and_return true

          expect(instance).to be_available
        end

        it 'is false if no work package exists/ is visible' do
          allow(WorkPackage)
            .to receive_message_chain(:visible, :exists?)
            .with(no_args)
            .and_return false

          expect(instance).not_to be_available
        end
      end
    end

    describe '#ar_object_filter?' do
      it 'is true' do
        expect(instance).to be_ar_object_filter
      end
    end

    describe '#allowed_values' do
      it 'raises an error' do
        expect { instance.allowed_values }.to raise_error NotImplementedError
      end
    end

    describe '#value_object' do
      let(:visible_wp) { FactoryBot.build_stubbed(:work_package) }

      it 'returns the work package for the values' do
        allow(WorkPackage)
          .to receive_message_chain(:visible, :for_projects, :find)
          .with(no_args)
          .with(project)
          .with(instance.values)
          .and_return([visible_wp])

        expect(instance.value_objects)
          .to match_array [visible_wp]
      end
    end

    describe '#allowed_objects' do
      it 'raises an error' do
        expect { instance.allowed_objects }.to raise_error NotImplementedError
      end
    end

    describe '#valid_values!' do
      let(:visible_wp) { FactoryBot.build_stubbed(:work_package) }
      let(:invisible_wp) { FactoryBot.build_stubbed(:work_package) }

      context 'within a project' do
        it 'removes all non existing/non visible ids' do
          instance.values = [visible_wp.id.to_s, invisible_wp.id.to_s, '999999']

          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :where, :pluck)
            .with(no_args)
            .with(project)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          instance.valid_values!

          expect(instance.values)
            .to match_array [visible_wp.id.to_s]
        end
      end

      context 'outside of a project' do
        let(:project) { nil }

        it 'removes all non existing/non visible ids' do
          instance.values = [visible_wp.id.to_s, invisible_wp.id.to_s, '999999']

          allow(WorkPackage)
            .to receive_message_chain(:visible, :where, :pluck)
            .with(no_args)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          instance.valid_values!

          expect(instance.values)
            .to match_array [visible_wp.id.to_s]
        end
      end
    end

    describe '#validate' do
      let(:visible_wp) { FactoryBot.build_stubbed(:work_package) }
      let(:invisible_wp) { FactoryBot.build_stubbed(:work_package) }

      context 'within a project' do
        it 'is valid if only visible wps are values' do
          instance.values = [visible_wp.id.to_s]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :where, :pluck)
            .with(no_args)
            .with(project)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          expect(instance).to be_valid
        end

        it 'is invalid if invisible wps are values' do
          instance.values = [invisible_wp.id.to_s, visible_wp.id.to_s]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :where, :pluck)
            .with(no_args)
            .with(project)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          expect(instance).not_to be_valid
        end
      end

      context 'outside of a project' do
        let(:project) { nil }

        it 'is valid if only visible wps are values' do
          instance.values = [visible_wp.id.to_s]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :where, :pluck)
            .with(no_args)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          expect(instance).to be_valid
        end

        it 'is invalid if invisible wps are values' do
          instance.values = [invisible_wp.id.to_s, visible_wp.id.to_s]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :where, :pluck)
            .with(no_args)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          expect(instance).not_to be_valid
        end
      end
    end
  end
end

shared_examples_for 'operators for relation filters' do
  context "on '=' operator" do
    before do
      instance.operator = '='
    end

    it 'returns the related work packages' do
      expect(WorkPackage.where(instance.where))
        .to match_array [related_wp]
    end
  end

  context "on '!' operator" do
    before do
      instance.operator = '!'
    end

    it 'returns the unrelated work packages' do
      expect(WorkPackage.where(instance.where))
        .to match_array [filter_value_wp, unrelated_wp]
    end
  end
end

shared_examples_for 'filter for relation' do
  describe '#where' do
    let!(:filter_value_wp) { FactoryBot.create(:work_package) }
    let(:wp_relation_type) { defined?(:relation_type) ? relation_type : raise('needs to be defined') }
    let!(:related_wp) do
      relation = Hash.new
      relation[wp_relation_type] = [filter_value_wp]
      FactoryBot.create(:work_package, relation)
    end

    let!(:unrelated_wp) { FactoryBot.create(:work_package) }

    before do
      instance.values = [filter_value_wp.id.to_s]
    end

    it_behaves_like 'operators for relation filters'
  end
end
