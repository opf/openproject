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

RSpec.describe Queries::Projects::Filters::AvailableProjectAttributesFilter do
  it_behaves_like "basic query filter" do
    let(:class_key) { :available_project_attributes }
    let(:type) { :list }
    let(:human_name) { "Available project attributes" }
  end

  it_behaves_like "list query filter", scope: false do
    shared_let(:project) { create(:project) }
    shared_let(:project_custom_field_mapping1) { create(:project_custom_field_project_mapping, project:) }
    shared_let(:project_custom_field_mapping2) { create(:project_custom_field_project_mapping, project:) }

    let(:valid_values) do
      [project_custom_field_mapping1.custom_field_id.to_s, project_custom_field_mapping2.custom_field_id.to_s]
    end
    let(:name) { "Available project attributes" }

    describe "#apply_to" do
      let(:values) { valid_values }

      let(:project_custom_field_project_mapping_handwritten_sql_subquery) do
        <<-SQL.squish
            SELECT "project_custom_field_project_mappings"."project_id"
              FROM "project_custom_field_project_mappings"
              WHERE "project_custom_field_project_mappings"."custom_field_id"
              IN (#{values.join(', ')})
        SQL
      end

      context 'for "="' do
        let(:operator) { "=" }

        it "is the same as handwriting the query" do
          handwritten_scope_sql = <<-SQL.squish
            SELECT "projects".* FROM "projects"
              WHERE "projects"."id" IN (#{project_custom_field_project_mapping_handwritten_sql_subquery})
          SQL

          expect(instance.apply_to(Project).to_sql).to eql handwritten_scope_sql
        end
      end

      context 'for "!"' do
        let(:operator) { "!" }

        it "is the same as handwriting the query" do
          handwritten_scope_sql = <<-SQL.squish
            SELECT "projects".* FROM "projects"
              WHERE "projects"."id" NOT IN (#{project_custom_field_project_mapping_handwritten_sql_subquery})
          SQL

          expect(instance.apply_to(Project).to_sql).to eql handwritten_scope_sql
        end
      end

      context "for an unsupported operator" do
        let(:operator) { "!=" }

        it "raises an error" do
          expect { instance.apply_to(Project) }.to raise_error("unsupported operator")
        end
      end
    end

    describe "#allowed_values" do
      it "is a list of the possible values" do
        expected = [
          [project_custom_field_mapping1.project_custom_field.name, project_custom_field_mapping1.custom_field_id],
          [project_custom_field_mapping2.project_custom_field.name, project_custom_field_mapping2.custom_field_id]
        ]

        expect(instance.allowed_values).to match_array(expected)
      end
    end
  end
end
