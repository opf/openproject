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

RSpec.describe Query::Results, "Sorting by custom field" do
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
          project:).tap do |q|
      q.filters.clear
      q.sort_criteria = sort_criteria
    end
  end

  before do
    login_as(user)
  end

  def wp_with_cf_value(value)
    create(:work_package, type:, project:, custom_values: { custom_field.id => value })
  end

  def wp_without_cf_value
    create(:work_package, type:, project:)
  end

  shared_examples "it sorts" do
    let(:work_packages_desc) { work_packages.reverse }

    before { work_packages }

    work_package_attributes = ->(work_package) do
      {
        id: work_package.id,
        values: work_package.custom_values.map(&:value).sort
      }
    end

    context "in ascending order" do
      let(:sort_criteria) { [[custom_field.column_name, "asc"], %w[id asc]] }

      it "returns the correctly sorted result" do
        expect(query_results.work_packages).to eq_array(work_packages, &work_package_attributes)
      end
    end

    context "in descending order" do
      let(:sort_criteria) { [[custom_field.column_name, "desc"], %w[id asc]] }

      it "returns the correctly sorted result" do
        expect(query_results.work_packages).to eq_array(work_packages_desc, &work_package_attributes)
      end
    end
  end

  context "for string format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:string_wp_custom_field) }

      let(:work_packages) do
        [
          wp_without_cf_value,
          wp_with_cf_value("16"),
          wp_with_cf_value("6.25")
        ]
      end
    end
  end

  context "for link format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:link_wp_custom_field) }

      let(:work_packages) do
        [
          wp_without_cf_value,
          wp_with_cf_value("https://openproject.org/intro/"),
          wp_with_cf_value("https://openproject.org/pricing/")
        ]
      end
    end
  end

  context "for int format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:integer_wp_custom_field) }

      let(:work_packages) do
        [
          wp_without_cf_value,
          wp_with_cf_value("6"),
          wp_with_cf_value("16")
        ]
      end
    end
  end

  context "for float format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:float_wp_custom_field) }

      let(:work_packages) do
        [
          wp_without_cf_value,
          wp_with_cf_value("6.25"),
          wp_with_cf_value("16")
        ]
      end
    end
  end

  context "for date format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:date_wp_custom_field) }

      let(:work_packages) do
        [
          wp_without_cf_value,
          wp_with_cf_value("2024-01-01"),
          wp_with_cf_value("2030-01-01"),
          wp_with_cf_value("999-01-01") # TODO: should be at index 1
        ]
      end
    end
  end

  context "for bool format" do
    include_examples "it sorts" do
      let(:custom_field) { create(:boolean_wp_custom_field) }

      let(:work_packages) do
        [
          wp_without_cf_value,
          wp_with_cf_value("0"),
          wp_with_cf_value("1")
        ]
      end
    end
  end

  context "for list format" do
    let(:possible_values) { %w[100 3 20] }
    let(:id_by_value) { custom_field.possible_values.to_h { [_1.value, _1.id] } }

    context "if not allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:list_wp_custom_field, possible_values:) }

        let(:work_packages) do
          [
            wp_without_cf_value,
            # sorting is done by position, and not by value
            wp_with_cf_value(id_by_value.fetch("100")),
            wp_with_cf_value(id_by_value.fetch("3")),
            wp_with_cf_value(id_by_value.fetch("20")),
          ]
        end
      end
    end

    context "if allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:multi_list_wp_custom_field, possible_values:) }

        let(:work_packages) do
          [
            wp_without_cf_value,
            wp_with_cf_value(id_by_value.fetch_values("100")),            # 100
            wp_with_cf_value(id_by_value.fetch_values("3", "100")),       # 100, 3
            wp_with_cf_value(id_by_value.fetch_values("3", "20", "100")), # 100, 3, 20
            wp_with_cf_value(id_by_value.fetch_values("3", "100", "20")), # 100, 3, 20
            wp_with_cf_value(id_by_value.fetch_values("20", "3", "100")), # 100, 3, 20
            wp_with_cf_value(id_by_value.fetch_values("20", "100", "3")), # 100, 3, 20
            wp_with_cf_value(id_by_value.fetch_values("100", "3", "20")), # 100, 3, 20
            wp_with_cf_value(id_by_value.fetch_values("100", "20", "3")), # 100, 3, 20
            wp_with_cf_value(id_by_value.fetch_values("20", "100")),      # 100, 20
            wp_with_cf_value(id_by_value.fetch_values("3")),              # 3
            wp_with_cf_value(id_by_value.fetch_values("3", "20")),        # 3, 20
            wp_with_cf_value(id_by_value.fetch_values("20")),             # 20
          ]
        end

        let(:work_packages_desc) do
          indexes = work_packages.each_index.to_a
          # order of projects with same values in different order falls back on next column (id asc)
          indexes[3...9] = indexes[3...9].reverse
          work_packages.values_at(*indexes.reverse)
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
      users.each do |user|
        create(:member, project:, principal: user, roles: [role])
      end
    end

    context "if not allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:user_wp_custom_field) }

        let(:work_packages) do
          [
            wp_without_cf_value,
            wp_with_cf_value(id_by_login.fetch("ax")),
            wp_with_cf_value(id_by_login.fetch("ba")),
            wp_with_cf_value(id_by_login.fetch("bb1")),
            wp_with_cf_value(id_by_login.fetch("bb2")),
          ]
        end
      end
    end

    context "if allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:multi_user_wp_custom_field) }

        let(:work_packages) do
          [
            wp_without_cf_value,
            wp_with_cf_value(id_by_login.fetch_values("ax")),        # ax
            wp_with_cf_value(id_by_login.fetch_values("bb1", "ax")), # ax, bb1
            wp_with_cf_value(id_by_login.fetch_values("ax", "bb1")), # ax, bb1
            wp_with_cf_value(id_by_login.fetch_values("ba")),        # ba
            wp_with_cf_value(id_by_login.fetch_values("bb1", "ba")), # ba, bb1
            wp_with_cf_value(id_by_login.fetch_values("ba", "bb2")), # ba, bb2
          ]
        end

        let(:work_packages_desc) do
          indexes = work_packages.each_index.to_a
          # order of projects with same values in different order falls back on next column (id asc)
          indexes[2...4] = indexes[2...4].reverse
          work_packages.values_at(*indexes.reverse)
        end
      end
    end
  end

  context "for version format" do
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
        let(:custom_field) { create(:version_wp_custom_field) }

        let(:work_packages) do
          [
            wp_without_cf_value,
            wp_with_cf_value(id_by_name.fetch("10.10.10")),
            wp_with_cf_value(id_by_name.fetch("10.10.2")),
            wp_with_cf_value(id_by_name.fetch("10.2")),
            wp_with_cf_value(id_by_name.fetch("9")),
          ]
        end
      end
    end

    context "if allowing multi select" do
      include_examples "it sorts" do
        let(:custom_field) { create(:multi_version_wp_custom_field) }

        let(:work_packages) do
          [
            wp_without_cf_value,
            wp_with_cf_value(id_by_name.fetch_values("10.10.10")),        # 10.10.10
            wp_with_cf_value(id_by_name.fetch_values("9", "10.10.10")),   # 10.10.10, 9
            wp_with_cf_value(id_by_name.fetch_values("10.10.10", "9")),   # 10.10.10, 9
            wp_with_cf_value(id_by_name.fetch_values("10.10.2")),         # 10.10.2
            wp_with_cf_value(id_by_name.fetch_values("10.2", "10.10.2")), # 10.10.2, 10.2
            wp_with_cf_value(id_by_name.fetch_values("10.10.2", "9")),    # 10.10.2, 9
          ]
        end

        let(:work_packages_desc) do
          indexes = work_packages.each_index.to_a
          # order of projects with same values in different order falls back on next column (id asc)
          indexes[2...4] = indexes[2...4].reverse
          work_packages.values_at(*indexes.reverse)
        end
      end
    end
  end
end
