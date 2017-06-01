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

describe Queries::Projects::ProjectQuery, type: :model do
  let(:instance) { described_class.new }
  let(:base_scope) { Project.all }

  context 'without a filter' do
    describe '#results' do
      it 'is the same as getting all projects' do
        expect(instance.results.to_sql).to eql base_scope.to_sql
      end
    end
  end

  context 'with an ancestor filter - "=" operator' do
    before do
      instance.where('ancestor', '=', ['8'])
    end

    describe '#results' do
      it 'is the same as handwriting the query' do
        projects_table = Project.arel_table
        projects_ancestor_table = projects_table.alias(:ancestor_projects)

        condition = projects_table[:lft]
                    .gt(projects_ancestor_table[:lft])
                    .and(projects_table[:rgt].lt(projects_ancestor_table[:rgt]))
                    .and(projects_ancestor_table[:id].in(['8']))

        arel = projects_table
               .join(projects_ancestor_table)
               .on(condition)

        expected = base_scope.joins(arel.join_sources)

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context 'with an ancestor filter - "!" operator' do
    before do
      instance.where('ancestor', '!', ['8'])
    end

    describe '#results' do
      it 'is the same as handwriting the query' do
        projects_table = Project.arel_table
        projects_ancestor_table = projects_table.alias(:ancestor_projects)

        condition = projects_table[:lft]
                    .gt(projects_ancestor_table[:lft])
                    .and(projects_table[:rgt].lt(projects_ancestor_table[:rgt]))

        arel = projects_table
               .outer_join(projects_ancestor_table)
               .on(condition)

        where_condition = projects_ancestor_table[:id]
                          .not_in(['8'])
                          .or(projects_ancestor_table[:id].eq(nil))

        expected = base_scope
                   .joins(arel.join_sources)
                   .where(where_condition)

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end
end
