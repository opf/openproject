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

describe Queries::Members::Filters::NameFilter, type: :model do
  include_context 'filter tests'
  let(:values) { ['A name'] }
  let(:model) { Member.joins(:principal) }

  it_behaves_like 'basic query filter' do
    let(:class_key) { :name }
    let(:type) { :string }
    let(:model) { Member.joins(:principal) }

    describe '#allowed_values' do
      it 'is nil' do
        expect(instance.allowed_values).to be_nil
      end
    end
  end

  describe '#scope' do
    before do
      allow(Setting)
        .to receive(:user_format)
        .and_return(:firstname)
    end

    context 'for "="' do
      let(:operator) { '=' }

      it 'is the same as handwriting the query' do
        expected = model.where("LOWER(users.firstname) IN ('#{values.first.downcase}')")

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "!"' do
      let(:operator) { '!' }

      it 'is the same as handwriting the query' do
        expected = model.where("LOWER(users.firstname) NOT IN ('#{values.first.downcase}')")

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "~"' do
      let(:operator) { '~' }

      it 'is the same as handwriting the query' do
        expected = model.where("LOWER(users.firstname) LIKE '%#{values.first.downcase}%'")

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end

    context 'for "!~"' do
      let(:operator) { '!~' }

      it 'is the same as handwriting the query' do
        expected = model.where("LOWER(users.firstname) NOT LIKE '%#{values.first.downcase}%'")

        expect(instance.scope.to_sql).to eql expected.to_sql
      end
    end
  end
end
