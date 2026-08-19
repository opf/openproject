# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe Query::Results, "Sorting and grouping at the same time" do
  shared_let(:user) { create(:admin) }

  let(:query_results) do
    described_class.new query
  end

  let(:type) { create(:type_standard, custom_fields: [custom_field]) }
  let(:project) do
    create(:project,
           types: [type],
           work_package_custom_fields: [custom_field])
  end

  let(:query) do
    build(:query,
          user:,
          show_hierarchies: false,
          project:,
          group_by: group_by).tap do |q|
      q.filters.clear
      q.sort_criteria = sort_criteria
    end
  end

  current_user { user }

  def wp_with(custom_field_value: nil, **attributes)
    attributes[:custom_values] = { custom_field.id => custom_field_value } if custom_field_value

    create(:work_package, type:, project:, **attributes)
  end

  def wp_without
    create(:work_package, type:, project:)
  end

  shared_examples "it sorts asc" do
    let(:work_packages_desc) { work_packages.reverse }

    before { work_packages }

    let(:sort_criteria) { [[custom_field.column_name, "asc"], %w[id asc]] }

    it "returns the correctly sorted result" do
      work_package_attributes = ->(work_package) do
        {
          id: work_package.id,
          values: [work_package.send("#{group_by}_id")] + work_package.custom_values.map(&:value).sort
        }
      end

      expect(query_results.work_packages).to eq_array(work_packages, &work_package_attributes)
    end
  end

  shared_examples "it sorts desc" do
    let(:sort_criteria) { [[custom_field.column_name, "desc"], %w[id asc]] }

    it "returns the correctly sorted result" do
      work_package_attributes = ->(work_package) do
        {
          id: work_package.id,
          values: [work_package.send("#{group_by}_id")] + work_package.custom_values.map(&:value).sort
        }
      end

      expect(query_results.work_packages).to eq_array(work_packages, &work_package_attributes)
    end
  end

  context "when grouping by assignee and sorting by user format cf" do
    let(:group_by) { :assigned_to }

    shared_let(:users) do
      [
        create(:user, lastname: "B", firstname: "B", login: "bb1", mail: "bb1@o.p"),
        create(:user, lastname: "B", firstname: "B", login: "bb2", mail: "bb2@o.p"),
        create(:user, lastname: "B", firstname: "A", login: "ba", mail: "ba@o.p"),
        create(:user, lastname: "A", firstname: "X", login: "ax", mail: "ax@o.p")
      ]
    end
    shared_let(:id_by_login) { users.to_h { [it.login, it.id] } }

    shared_let(:role) { create(:project_role) }

    before do
      users.each do |user|
        create(:member, project:, principal: user, roles: [role])
      end
    end

    context "if not allowing multi select" do
      it_behaves_like "it sorts asc" do
        let(:custom_field) { create(:user_wp_custom_field) }

        let(:work_packages) do
          [
            wp_with(assigned_to_id: id_by_login.fetch("bb1")),
            wp_with(assigned_to_id: id_by_login.fetch("bb1"), custom_field_value: id_by_login.fetch("ax")),
            wp_with(assigned_to_id: id_by_login.fetch("bb1"), custom_field_value: id_by_login.fetch("ba")),
            wp_with(assigned_to_id: id_by_login.fetch("bb1"), custom_field_value: id_by_login.fetch("bb1")),
            wp_with(assigned_to_id: id_by_login.fetch("bb1"), custom_field_value: id_by_login.fetch("bb2")),
            wp_without,
            wp_with(custom_field_value: id_by_login.fetch("ax")),
            wp_with(custom_field_value: id_by_login.fetch("ba")),
            wp_with(custom_field_value: id_by_login.fetch("bb1")),
            wp_with(custom_field_value: id_by_login.fetch("bb2"))
          ]
        end
      end

      it_behaves_like "it sorts desc" do
        let(:custom_field) { create(:user_wp_custom_field) }

        let(:work_packages) do
          [
            wp_with(assigned_to_id: id_by_login.fetch("bb1"), custom_field_value: id_by_login.fetch("bb2")),
            wp_with(assigned_to_id: id_by_login.fetch("bb1"), custom_field_value: id_by_login.fetch("bb1")),
            wp_with(assigned_to_id: id_by_login.fetch("bb1"), custom_field_value: id_by_login.fetch("ba")),
            wp_with(assigned_to_id: id_by_login.fetch("bb1"), custom_field_value: id_by_login.fetch("ax")),
            wp_with(assigned_to_id: id_by_login.fetch("bb1")),
            wp_with(custom_field_value: id_by_login.fetch("bb2")),
            wp_with(custom_field_value: id_by_login.fetch("bb1")),
            wp_with(custom_field_value: id_by_login.fetch("ba")),
            wp_with(custom_field_value: id_by_login.fetch("ax")),
            wp_without
          ]
        end
      end
    end

    context "if allowing multi select" do
      let(:custom_field) { create(:multi_user_wp_custom_field) }

      it_behaves_like "it sorts asc" do
        let(:work_packages) do
          [
            wp_with(assigned_to_id: id_by_login.fetch("bb1")),
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("ax")),        # ax
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("bb1", "ax")), # ax, bb1
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("ax", "bb1")), # ax, bb1
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("ba")),        # ba
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("bb1", "ba")), # ba, bb1
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("ba", "bb2")), # ba, bb2
            wp_without,
            wp_with(custom_field_value: id_by_login.fetch_values("ax")),        # ax
            wp_with(custom_field_value: id_by_login.fetch_values("bb1", "ax")), # ax, bb1
            wp_with(custom_field_value: id_by_login.fetch_values("ax", "bb1")), # ax, bb1
            wp_with(custom_field_value: id_by_login.fetch_values("ba")),        # ba
            wp_with(custom_field_value: id_by_login.fetch_values("bb1", "ba")), # ba, bb1
            wp_with(custom_field_value: id_by_login.fetch_values("ba", "bb2"))  # ba, bb2
          ]
        end
      end

      it_behaves_like "it sorts desc" do
        let(:work_packages) do
          [
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("ba", "bb2")), # ba, bb2
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("bb1", "ba")), # ba, bb1
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("ba")),        # ba
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("ax", "bb1")), # ax, bb1
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("bb1", "ax")), # ax, bb1
            wp_with(assigned_to_id: id_by_login.fetch("bb1"),
                    custom_field_value: id_by_login.fetch_values("ax")),        # ax
            wp_with(assigned_to_id: id_by_login.fetch("bb1")),
            wp_with(custom_field_value: id_by_login.fetch_values("ba", "bb2")), # ba, bb2
            wp_with(custom_field_value: id_by_login.fetch_values("bb1", "ba")), # ba, bb1
            wp_with(custom_field_value: id_by_login.fetch_values("ba")),        # ba
            wp_with(custom_field_value: id_by_login.fetch_values("ax", "bb1")), # ax, bb1
            wp_with(custom_field_value: id_by_login.fetch_values("bb1", "ax")), # ax, bb1
            wp_with(custom_field_value: id_by_login.fetch_values("ax")),        # ax
            wp_without
          ]
        end
      end
    end
  end

  context "when grouping by version and sorting by version format cf" do
    let(:versions) do
      [
        create(:version, project:, sharing: "system", name: "10.10.10"),
        create(:version, project:, sharing: "system", name: "10.10.2"),
        create(:version, project:, sharing: "system", name: "10.2"),
        create(:version, project:, sharing: "system", name: "9")
      ]
    end
    let(:id_by_name) { versions.to_h { [it.name, it.id] } }
    let(:group_by) { :version }

    context "if not allowing multi select" do
      let(:custom_field) { create(:version_wp_custom_field) }

      it_behaves_like "it sorts asc" do
        let(:work_packages) do
          [
            wp_with(version_id: id_by_name.fetch("9")),
            wp_with(version_id: id_by_name.fetch("9"), custom_field_value: id_by_name.fetch("9")),
            wp_with(version_id: id_by_name.fetch("10.10.2")),
            wp_with(version_id: id_by_name.fetch("10.10.2"), custom_field_value: id_by_name.fetch("9")),
            wp_with(version_id: id_by_name.fetch("10.10.2"), custom_field_value: id_by_name.fetch("10.2")),
            wp_without,
            wp_with(custom_field_value: id_by_name.fetch("9")),
            wp_with(custom_field_value: id_by_name.fetch("10.2")),
            wp_with(custom_field_value: id_by_name.fetch("10.10.2")),
            wp_with(custom_field_value: id_by_name.fetch("10.10.10"))
          ]
        end
      end

      it_behaves_like "it sorts desc" do
        let(:work_packages) do
          [
            wp_with(version_id: id_by_name.fetch("9"), custom_field_value: id_by_name.fetch("9")),
            wp_with(version_id: id_by_name.fetch("9")),
            wp_with(version_id: id_by_name.fetch("10.10.2"), custom_field_value: id_by_name.fetch("10.2")),
            wp_with(version_id: id_by_name.fetch("10.10.2"), custom_field_value: id_by_name.fetch("9")),
            wp_with(version_id: id_by_name.fetch("10.10.2")),
            wp_with(custom_field_value: id_by_name.fetch("10.10.10")),
            wp_with(custom_field_value: id_by_name.fetch("10.10.2")),
            wp_with(custom_field_value: id_by_name.fetch("10.2")),
            wp_with(custom_field_value: id_by_name.fetch("9")),
            wp_without
          ]
        end
      end
    end

    context "if allowing multi select" do
      let(:custom_field) { create(:multi_version_wp_custom_field) }

      it_behaves_like "it sorts asc" do
        let(:work_packages) do
          [
            wp_with(version_id: id_by_name.fetch("10.10.10")),
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.10.2", "9")),    # 9, 10.10.2
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.10.10", "9")),   # 9, 10.10.10
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("9", "10.10.10")),   # 9, 10.10.10
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.2", "10.10.2")), # 10.2, 10.10.2
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.10.2")),         # 10.10.2
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.10.10")),        # 10.10.10
            wp_without,
            wp_with(custom_field_value: id_by_name.fetch_values("10.10.2", "9")),    # 9, 10.10.2
            wp_with(custom_field_value: id_by_name.fetch_values("10.10.10", "9")),   # 9, 10.10.10
            wp_with(custom_field_value: id_by_name.fetch_values("9", "10.10.10")),   # 9, 10.10.10
            wp_with(custom_field_value: id_by_name.fetch_values("10.2", "10.10.2")), # 10.2, 10.10.2
            wp_with(custom_field_value: id_by_name.fetch_values("10.10.2")),         # 10.10.2
            wp_with(custom_field_value: id_by_name.fetch_values("10.10.10"))         # 10.10.10
          ]
        end
      end

      it_behaves_like "it sorts desc" do
        let(:work_packages) do
          [
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.10.10")),        # 10.10.10
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.10.2")),         # 10.10.2
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.2", "10.10.2")), # 10.2, 10.10.2
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("9", "10.10.10")),   # 9, 10.10.10
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.10.10", "9")),   # 9, 10.10.10
            wp_with(version_id: id_by_name.fetch("10.10.10"),
                    custom_field_value: id_by_name.fetch_values("10.10.2", "9")),    # 9, 10.10.2
            wp_with(version_id: id_by_name.fetch("10.10.10")),
            wp_with(custom_field_value: id_by_name.fetch_values("10.10.10")),        # 10.10.10
            wp_with(custom_field_value: id_by_name.fetch_values("10.10.2")),         # 10.10.2
            wp_with(custom_field_value: id_by_name.fetch_values("10.2", "10.10.2")), # 10.2, 10.10.2
            wp_with(custom_field_value: id_by_name.fetch_values("9", "10.10.10")),   # 9, 10.10.10
            wp_with(custom_field_value: id_by_name.fetch_values("10.10.10", "9")),   # 9, 10.10.10
            wp_with(custom_field_value: id_by_name.fetch_values("10.10.2", "9")),    # 9, 10.10.2
            wp_without
          ]
        end
      end
    end
  end
end
