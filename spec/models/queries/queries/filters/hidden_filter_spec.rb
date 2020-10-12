#-- encoding: UTF-8

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

require 'spec_helper'

describe Queries::Queries::Filters::HiddenFilter, type: :model do
  let(:instance) do
    described_class.create!(name: 'hidden', context: nil, operator: operator, values: values)
  end

  it_behaves_like 'basic query filter' do
    let(:class_key) { :hidden }
    let(:type) { :list }
  end

  include_context 'filter tests'
  let(:type) { :list }

  describe '#scope' do
    context 'for "= t"' do
      let(:operator) { '=' }
      let(:values) { ['t'] }

      it 'is the same as handwriting the query' do
        expected = Query.where(["queries.hidden IN (?)", values])

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "= f"' do
      let(:operator) { '=' }
      let(:values) { ['f'] }

      it 'is the same as handwriting the query' do
        sql = "queries.hidden IS NULL OR queries.hidden IN (?)"
        expected = Query.where([sql, values])

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "!"' do
      let(:operator) { '!' }
      let(:values) { ['f'] }

      it 'is the same as handwriting the query' do
        expected = Query.where(["queries.hidden IN ('t')", values])

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end
  end

  describe '#valid?' do
    let(:operator) { '=' }

    context 'for true value' do
      let(:values) { ['t'] }

      it 'is valid' do
        expect(instance).to be_valid
      end
    end

    context 'for false value' do
      let(:values) { ['f'] }

      it 'is valid' do
        expect(instance).to be_valid
      end
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
