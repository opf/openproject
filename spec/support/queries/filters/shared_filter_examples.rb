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

shared_context 'filter tests' do
  let(:context) { nil }
  let(:values) { ['bogus'] }
  let(:operator) { '=' }
  let(:instance) do
    filter = described_class.new
    filter.context = context
    filter.operator = operator
    filter.values = values
    filter
  end
  let(:name) { model.human_attribute_name((instance_key || class_key).to_s.gsub('_id', '')) }
  let(:model) { WorkPackage }
end

shared_examples_for 'basic query filter' do
  include_context 'filter tests'

  let(:context) { FactoryGirl.build_stubbed(:query, project: project) }
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:instance_key) { nil }
  let(:class_key) { raise 'needs to be defined' }
  let(:type) { raise 'needs to be defined' }
  let(:order) { nil }

  describe '.key' do
    it 'is the defined key' do
      expect(described_class.key).to eql(class_key)
    end
  end

  describe '#name' do
    it 'is the defined key' do
      expect(instance.name).to eql(instance_key || class_key)
    end
  end

  describe '#order' do
    it 'has the defined order' do
      if order
        expect(instance.order).to eql(order)
      end
    end
  end

  describe '#type' do
    it 'is the defined filter type' do
      expect(instance.type).to eql(type)
    end
  end

  describe '#human_name' do
    it 'is the l10 name for the filter' do
      expect(instance.human_name).to eql(name)
    end
  end
end

shared_examples_for 'list query filter' do
  include_context 'filter tests'
  let(:attribute) { raise "needs to be defined" }
  let(:type) { :list }

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
    if joins
      joins
    else
      model.table_name
    end
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
