#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::Members::Filters::AlsoProjectMemberFilter do
  it_behaves_like "boolean query filter", scope: false do
    let(:model) { Member }
    let(:attribute) { nil }

    let(:exists_query) do
      <<~SQL.squish
        SELECT 1 FROM "members" as "project_members"
        WHERE
          project_members.user_id = members.user_id AND
          project_members.project_id = members.project_id AND
          project_members.entity_type IS NULL AND
          project_members.entity_id IS NULL AND
          project_members.id != members.id
      SQL
    end

    describe "#where" do
      let(:operator) { "=" }

      context "for true" do
        let(:values) { [OpenProject::Database::DB_VALUE_TRUE] }

        it "is the same as handwriting the query" do
          expected = expected_base_scope.where("EXISTS (#{exists_query})")
          expect(instance.apply_to(model).to_sql).to eql expected.to_sql
        end
      end

      context "for false" do
        let(:values) { [OpenProject::Database::DB_VALUE_FALSE] }

        it "is the same as handwriting the query" do
          expected = expected_base_scope.where("NOT EXISTS (#{exists_query})")
          expect(instance.apply_to(model).to_sql).to eql expected.to_sql
        end
      end
    end
  end
end
