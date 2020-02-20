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

describe Queries::Roles::Filters::GrantableFilter, type: :model do
  it_behaves_like 'basic query filter' do
    let(:class_key) { :grantable }
    let(:type) { :list }
    let(:model) { Role }
  end

  it_behaves_like 'boolean query filter', scope: false do
    let(:model) { Role }
    let(:attribute) { :type }

    describe '#scope' do
      context 'for the true value' do
        let(:values) { [OpenProject::Database::DB_VALUE_TRUE] }

        context 'for "="' do
          let(:operator) { '=' }

          it 'is the same as handwriting the query' do
            expected = expected_base_scope
                       .where(["#{expected_table_name}.builtin IN (?)", Role::NON_BUILTIN])

            expect(instance.scope.to_sql).to eql expected.to_sql
          end
        end

        context 'for "!"' do
          let(:operator) { '!' }

          it 'is the same as handwriting the query' do
            expected = expected_base_scope
                       .where(["#{expected_table_name}.builtin NOT IN (?)", Role::NON_BUILTIN])

            expect(instance.scope.to_sql).to eql expected.to_sql
          end
        end
      end

      context 'for the false value' do
        let(:values) { [OpenProject::Database::DB_VALUE_FALSE] }

        context 'for "="' do
          let(:operator) { '=' }

          it 'is the same as handwriting the query' do
            expected = expected_base_scope
                       .where(["#{expected_table_name}.builtin IN (?)", [Role::BUILTIN_ANONYMOUS, Role::BUILTIN_NON_MEMBER]])

            expect(instance.scope.to_sql).to eql expected.to_sql
          end
        end

        context 'for "!"' do
          let(:operator) { '!' }

          it 'is the same as handwriting the query' do
            expected = expected_base_scope
                       .where(["#{expected_table_name}.builtin NOT IN (?)", [Role::BUILTIN_ANONYMOUS, Role::BUILTIN_NON_MEMBER]])

            expect(instance.scope.to_sql).to eql expected.to_sql
          end
        end
      end
    end
  end
end
