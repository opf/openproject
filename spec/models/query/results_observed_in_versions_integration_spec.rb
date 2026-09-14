# frozen_string_literal: true

# --copyright
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

RSpec.describe Query::Results, "Grouping and sorting for observed in versions" do
  let(:query_results) do
    described_class.new query
  end
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           firstname: "user",
           lastname: "1",
           member_with_permissions: { project => [:view_work_packages] })
  end

  let(:alpha_version) do
    create(:version, name: "1. Alpha", project:)
  end

  let(:beta_version) do
    create(:version, name: "2. Beta", project:)
  end

  let!(:alpha_wp) do
    create_wp_with_observed_in_versions("Alpha wp", [alpha_version])
  end
  let!(:both_versions_wp) do
    create_wp_with_observed_in_versions("Both versions wp", [beta_version, alpha_version])
  end
  let!(:beta_wp) do
    create_wp_with_observed_in_versions("Beta wp", [beta_version])
  end
  let!(:no_version_wp) do
    create(:work_package, subject: "No version wp", project:)
  end

  let(:group_by) { nil }
  let(:sort_criteria) { [["observed_in_versions", "asc"]] }

  let(:query) do
    build(:query,
          user:,
          group_by:,
          show_hierarchies: false,
          project:).tap do |q|
      q.filters.clear
      q.sort_criteria = sort_criteria
    end
  end

  # Sorted by the aggregated version names ("1. alpha" < "1. alpha 2. beta" < "2. beta" < NULL)
  let(:work_packages_asc) { [alpha_wp, both_versions_wp, beta_wp, no_version_wp] }
  let(:work_packages_desc) { work_packages_asc.reverse }

  def create_wp_with_observed_in_versions(subject, versions, **attributes)
    create(:work_package, subject:, project:, **attributes).tap do |wp|
      versions.each do |version|
        create(:work_package_version, work_package: wp, version:, kind: :observed_in)
      end
    end
  end

  before do
    login_as(user)
  end

  describe "sorting ASC by observed in versions" do
    let(:sort_criteria) { [["observed_in_versions", "asc"]] }

    it "sorts by the aggregated version names with absent versions last" do
      expect(query_results.work_packages.pluck(:id))
        .to eq work_packages_asc.map(&:id)
    end
  end

  describe "sorting DESC by observed in versions" do
    let(:sort_criteria) { [["observed_in_versions", "desc"]] }

    it "sorts by the aggregated version names with absent versions first" do
      expect(query_results.work_packages.pluck(:id))
        .to eq work_packages_desc.map(&:id)
    end
  end

  describe "grouping by observed in versions" do
    let(:group_by) { "observed_in_versions" }

    it "groups by the set of assigned versions" do
      # The set of versions is the group key, so {alpha, beta} is a group of
      # its own, distinct from {alpha} and {beta}. Work packages without any
      # observed in version are grouped under the empty set.
      expect(query_results.work_package_count_by_group)
        .to eql([alpha_version] => 1,
                [alpha_version, beta_version] => 1,
                [beta_version] => 1,
                [] => 1)

      # Group keys are sorted like the work packages themselves
      expect(query_results.work_package_count_by_group.keys)
        .to eql [[alpha_version], [alpha_version, beta_version], [beta_version], []]

      # Groups are contiguous in the row order
      expect(query_results.work_packages.pluck(:id))
        .to eq work_packages_asc.map(&:id)
    end

    context "with sums displayed" do
      let(:query) do
        build(:query,
              user:,
              group_by:,
              show_hierarchies: false,
              project:).tap do |q|
          q.filters.clear
          q.sort_criteria = sort_criteria
          q.display_sums = true
        end
      end

      let!(:alpha_wp) do
        create_wp_with_observed_in_versions("Alpha wp", [alpha_version], estimated_hours: 2)
      end
      let!(:both_versions_wp) do
        create_wp_with_observed_in_versions("Both versions wp", [beta_version, alpha_version], estimated_hours: 3)
      end

      it "sums per version set" do
        sums = query_results.all_group_sums.transform_values do |by_column|
          by_column.transform_keys(&:name)[:estimated_hours]
        end

        expect(sums)
          .to eq([alpha_version] => 2.0,
                 [alpha_version, beta_version] => 3.0,
                 [beta_version] => nil,
                 [] => nil)
      end
    end
  end

  context "with equally named versions in different projects" do
    let(:other_project) { create(:project) }
    let(:user) do
      create(:user,
             firstname: "user",
             lastname: "1",
             member_with_permissions: {
               project => [:view_work_packages],
               other_project => [:view_work_packages]
             })
    end

    let(:same_name_version) do
      create(:version, name: alpha_version.name, project: other_project)
    end

    let!(:same_name_wp) do
      create(:work_package, subject: "Same name other project wp", project: other_project).tap do |wp|
        create(:work_package_version, work_package: wp, version: same_name_version, kind: :observed_in)
      end
    end

    let(:query) do
      build(:query,
            user:,
            group_by: "observed_in_versions",
            show_hierarchies: false,
            project: nil).tap do |q|
        q.filters.clear
        q.sort_criteria = sort_criteria
      end
    end

    it "keeps the equally named version sets in separate groups" do
      expect(query_results.work_package_count_by_group)
        .to eql([alpha_version] => 1,
                [same_name_version] => 1,
                [alpha_version, beta_version] => 1,
                [beta_version] => 1,
                [] => 1)
    end
  end
end
