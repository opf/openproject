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

RSpec.describe Queries::Storages::Projects::Filter::StoragesFilter do
  it_behaves_like "basic query filter" do
    let(:model) { Project }
    let(:class_key) { :storages }
    let(:type) { :list }
  end

  it_behaves_like "list query filter", scope: false do
    let(:model) { Project }
    shared_let(:project) { create(:project) }
    shared_let(:storage1) { create(:storage, :as_generic) }
    shared_let(:storage2) { create(:storage, :as_generic) }

    let(:valid_values) do
      [storage1.id, storage2.id]
    end
    let(:name) { "Available project attributes" }

    describe "#apply_to" do
      let(:values) { valid_values }

      let(:project_ids_from_project_storages_handwritten_sql) do
        <<-SQL.squish
            SELECT "project_storages"."project_id"
              FROM "project_storages"
              WHERE "project_storages"."storage_id"
              IN (#{values.join(', ')})
        SQL
      end

      context 'for "="' do
        let(:operator) { "=" }

        it "is the same as handwriting the query" do
          handwritten_scope_sql = <<-SQL.squish
            SELECT "projects".* FROM "projects"
              WHERE "projects"."id" IN (#{project_ids_from_project_storages_handwritten_sql})
          SQL

          expect(instance.apply_to(Project).to_sql).to eql handwritten_scope_sql
        end
      end

      context 'for "!"' do
        let(:operator) { "!" }

        it "is the same as handwriting the query" do
          handwritten_scope_sql = <<-SQL.squish
            SELECT "projects".* FROM "projects"
              WHERE "projects"."id" NOT IN (#{project_ids_from_project_storages_handwritten_sql})
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
          [storage1.name, storage1.id],
          [storage2.name, storage2.id]
        ]

        expect(instance.allowed_values).to match_array(expected)
      end
    end
  end
end
