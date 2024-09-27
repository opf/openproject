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

RSpec.describe ProjectQuery, "order using CustomFieldOrder" do
  shared_let(:user) { create(:admin) }

  let(:query_results) do
    described_class.new.order(custom_field.column_name => direction, id: :asc).results.to_a
  end

  before do
    login_as(user)
  end

  def cf_values(*values)
    values.map do |value|
      CustomValue.new(custom_field_id: custom_field.id, value:)
    end
  end

  def project_with_cf_value(*values)
    create(:public_project, custom_values: cf_values(*values))
  end

  def project_without_cf_value
    create(:public_project)
  end

  shared_examples "it sorts" do
    let(:projects_desc) { projects.reverse }

    before { projects }

    project_attributes = ->(project) do
      {
        id: project.id,
        values: project.custom_values.map(&:value).sort
      }
    end

    context "in ascending order" do
      let(:direction) { :asc }

      it "returns the correctly sorted result" do
        expect(query_results).to eq_array(projects, &project_attributes)
      end
    end

    context "in descending order" do
      let(:direction) { :desc }

      it "returns the correctly sorted result" do
        expect(query_results).to eq_array(projects_desc, &project_attributes)
      end
    end
  end

  context "for string format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:project_custom_field, :string) }

      let(:projects) do
        [
          project_without_cf_value,
          project_with_cf_value("16"),
          project_with_cf_value("6.25")
        ]
      end
    end
  end

  context "for link format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:project_custom_field, :link) }

      let(:projects) do
        [
          project_without_cf_value,
          project_with_cf_value("https://openproject.org/intro/"),
          project_with_cf_value("https://openproject.org/pricing/")
        ]
      end
    end
  end

  context "for int format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:project_custom_field, :integer) }

      let(:projects) do
        [
          project_with_cf_value("6"),
          project_with_cf_value("16"),
          project_without_cf_value # TODO: should be at index 0
        ]
      end
    end
  end

  context "for float format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:project_custom_field, :float) }

      let(:projects) do
        [
          project_with_cf_value("6.25"),
          project_with_cf_value("16"),
          project_without_cf_value # TODO: should be at index 0
        ]
      end
    end
  end

  context "for date format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:project_custom_field, :date) }

      let(:projects) do
        [
          project_without_cf_value,
          project_with_cf_value("2024-01-01"),
          project_with_cf_value("2030-01-01"),
          project_with_cf_value("999-01-01") # TODO: should be at index 1
        ]
      end
    end
  end

  context "for bool format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:project_custom_field, :boolean) }

      let(:projects) do
        [
          project_without_cf_value,
          project_with_cf_value("0"),
          project_with_cf_value("1")
        ]
      end
    end
  end

  context "for list format" do
    let(:possible_values) { %w[100 3 20] }
    let(:id_by_value) { custom_field.possible_values.to_h { [_1.value, _1.id] } }

    context "if not allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:project_custom_field, :list, possible_values:) }

        let(:projects) do
          [
            # sorting is done by position, and not by value
            project_with_cf_value(id_by_value.fetch("100")),
            project_with_cf_value(id_by_value.fetch("3")),
            project_with_cf_value(id_by_value.fetch("20")),
            project_without_cf_value # TODO: should be at index 0
          ]
        end
      end
    end

    context "if allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:project_custom_field, :list, :multi_value, possible_values:) }

        let(:projects) do
          [
            project_with_cf_value(*id_by_value.fetch_values("100")),            # 100
            project_with_cf_value(*id_by_value.fetch_values("3", "100")),       # 100, 3
            project_with_cf_value(*id_by_value.fetch_values("3", "20", "100")), # 100, 3, 20
            project_with_cf_value(*id_by_value.fetch_values("3", "100", "20")), # 100, 3, 20
            project_with_cf_value(*id_by_value.fetch_values("20", "3", "100")), # 100, 3, 20
            project_with_cf_value(*id_by_value.fetch_values("20", "100", "3")), # 100, 3, 20
            project_with_cf_value(*id_by_value.fetch_values("100", "3", "20")), # 100, 3, 20
            project_with_cf_value(*id_by_value.fetch_values("100", "20", "3")), # 100, 3, 20
            project_with_cf_value(*id_by_value.fetch_values("20", "100")),      # 100, 20
            project_with_cf_value(*id_by_value.fetch_values("3")),              # 3
            project_with_cf_value(*id_by_value.fetch_values("3", "20")),        # 3, 20
            project_with_cf_value(*id_by_value.fetch_values("20")),             # 20
            project_without_cf_value # TODO: decide on order of absent values
          ]
        end

        let(:projects_desc) do
          indexes = projects.each_index.to_a
          # order of values for a work package is ignored, so ordered by falling back on id asc
          indexes[2...8] = indexes[2...8].reverse
          projects.values_at(*indexes.reverse)
        end
      end
    end
  end

  context "for user format" do
    shared_let(:users) do
      [
        create(:user, lastname: "B", firstname: "B", login: "bb1", mail: "bb1@o.p"),
        create(:user, lastname: "B", firstname: "B", login: "bb2", mail: "bb2@o.p"),
        create(:user, lastname: "B", firstname: "A", login: "ba", mail: "ba@o.p"),
        create(:user, lastname: "A", firstname: "X", login: "ax", mail: "ax@o.p")
      ]
    end
    shared_let(:id_by_login) { users.to_h { [_1.login, _1.id] } }

    shared_let(:role) { create(:project_role) }

    before do
      projects.each do |project|
        users.each do |user|
          create(:member, project:, principal: user, roles: [role])
        end
      end
    end

    context "if not allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:project_custom_field, :user) }

        let(:projects) { custom_field_values.map { project_without_cf_value } }

        let(:custom_field_values) do
          [
            id_by_login.fetch("ax"),
            id_by_login.fetch("ba"),
            id_by_login.fetch("bb1"),
            id_by_login.fetch("bb2"),
            nil # TODO: should be at index 0
          ]
        end

        before do
          projects.zip(custom_field_values) do |project, value|
            project.update(custom_values: cf_values(value)) if value
          end
        end
      end
    end

    context "if allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:project_custom_field, :user, :multi_value) }

        let(:projects) { custom_field_values.map { project_without_cf_value } }

        let(:custom_field_values) do
          [
            id_by_login.fetch_values("ax"),        # ax
            id_by_login.fetch_values("bb1", "ax"), # ax, bb1
            id_by_login.fetch_values("ax", "bb1"), # ax, bb1
            id_by_login.fetch_values("ba"),        # ba
            id_by_login.fetch_values("bb1", "ba"), # ba, bb1
            id_by_login.fetch_values("ba", "bb2"), # ba, bb2
            [] # TODO: should be at index 0
          ]
        end

        before do
          projects.zip(custom_field_values) do |project, values|
            project.update(custom_values: cf_values(*values))
          end
        end

        let(:projects_desc) do
          indexes = projects.each_index.to_a
          # order of values for a work package is ignored, so ordered by falling back on id asc
          indexes[1...3] = indexes[1...3].reverse
          projects.values_at(*indexes.reverse)
        end
      end
    end
  end

  context "for version format" do
    let(:project) { project_without_cf_value }
    let(:versions) do
      [
        create(:version, project:, sharing: "system", name: "10.10.10"),
        create(:version, project:, sharing: "system", name: "10.10.2"),
        create(:version, project:, sharing: "system", name: "10.2"),
        create(:version, project:, sharing: "system", name: "9")
      ]
    end
    let(:id_by_name) { versions.to_h { [_1.name, _1.id] } }

    context "if not allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:project_custom_field, :version) }

        let(:projects) do
          [
            project_with_cf_value(id_by_name.fetch("10.10.10")),
            project_with_cf_value(id_by_name.fetch("10.10.2")),
            project_with_cf_value(id_by_name.fetch("10.2")),
            project_with_cf_value(id_by_name.fetch("9")),
            project # TODO: should be at index 0
          ]
        end
      end
    end

    context "if allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:project_custom_field, :version, :multi_value) }

        let(:projects) do
          [
            project_with_cf_value(*id_by_name.fetch_values("10.10.10")),        # 10.10.10
            project_with_cf_value(*id_by_name.fetch_values("9", "10.10.10")),   # 10.10.10, 9
            project_with_cf_value(*id_by_name.fetch_values("10.10.10", "9")),   # 10.10.10, 9
            project_with_cf_value(*id_by_name.fetch_values("10.10.2")),         # 10.10.2
            project_with_cf_value(*id_by_name.fetch_values("10.2", "10.10.2")), # 10.10.2, 10.2
            project_with_cf_value(*id_by_name.fetch_values("10.10.2", "9")),    # 10.10.2, 9
            project # TODO: should be at index 0
          ]
        end

        let(:projects_desc) do
          indexes = projects.each_index.to_a
          # order of values for a work package is ignored, so ordered by falling back on id asc
          indexes[1...3] = indexes[1...3].reverse
          projects.values_at(*indexes.reverse)
        end
      end
    end
  end
end
