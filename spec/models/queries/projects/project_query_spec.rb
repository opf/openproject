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

describe Queries::Projects::ProjectQuery, type: :model do
  let(:instance) { described_class.new }
  let(:base_scope) { Project.all }
  let(:current_user) { FactoryBot.build_stubbed(:admin) }

  before do
    login_as(current_user)
  end

  context 'without a filter' do
    context 'as an admin' do
      it 'is the same as getting all projects' do
        expect(instance.results.to_sql).to eql base_scope.to_sql
      end
    end

    context 'as a non admin' do
      let(:current_user) { FactoryBot.build_stubbed(:user) }

      it 'is the same as getting all visible projects' do
        expect(instance.results.to_sql).to eql base_scope.where(id: Project.visible).to_sql
      end
    end
  end

  context 'with a parent filter' do
    context 'with a "=" operator' do
      before do
        allow(Project)
          .to receive_message_chain(:visible, :pluck)
          .with(:id)
          .and_return([8])

        instance.where('parent_id', '=', ['8'])
      end

      it 'is the same as handwriting the query' do
        expected = base_scope
                     .where(["projects.parent_id IN (?)", ['8']])

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context 'with an ancestor filter' do
    context 'with a "=" operator' do
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

    context 'with a "!" operator' do
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
end
