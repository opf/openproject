# frozen_string_literal: true

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

RSpec.describe Query::Results, "Grouping and sorting for categories",
               with_flag: { work_package_multiple_categories: true },
               with_settings: { work_package_multiple_categories: true } do
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

  let(:alpha_category) do
    create(:category, name: "1. Alpha", project:)
  end

  let(:beta_category) do
    create(:category, name: "2. Beta", project:)
  end

  let!(:alpha_wp) do
    create_wp_with_categories("Alpha wp", [alpha_category])
  end
  let!(:both_categories_wp) do
    create_wp_with_categories("Both categories wp", [beta_category, alpha_category])
  end
  let!(:beta_wp) do
    create_wp_with_categories("Beta wp", [beta_category])
  end
  let!(:no_category_wp) do
    create(:work_package, subject: "No category wp", project:)
  end

  let(:group_by) { nil }
  let(:sort_criteria) { [["categories", "asc"]] }

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

  # Sorted by the aggregated category names ("1. alpha" < "1. alpha 2. beta" < "2. beta" < NULL)
  let(:work_packages_asc) { [alpha_wp, both_categories_wp, beta_wp, no_category_wp] }
  let(:work_packages_desc) { work_packages_asc.reverse }

  def create_wp_with_categories(subject, categories, **attributes)
    create(:work_package, subject:, project:, **attributes).tap do |wp|
      wp.category_ids_replacements = categories.map(&:id)
      wp.save!
    end
  end

  before do
    login_as(user)
  end

  describe "sorting ASC by categories" do
    let(:sort_criteria) { [["categories", "asc"]] }

    it "sorts by the aggregated category names with absent categories last" do
      expect(query_results.work_packages.pluck(:id))
        .to eq work_packages_asc.map(&:id)
    end
  end

  describe "sorting DESC by categories" do
    let(:sort_criteria) { [["categories", "desc"]] }

    it "sorts by the aggregated category names with absent categories first" do
      expect(query_results.work_packages.pluck(:id))
        .to eq work_packages_desc.map(&:id)
    end
  end

  describe "grouping by categories" do
    let(:group_by) { "categories" }

    it "groups by the set of assigned categories" do
      # The set of categories is the group key, so {alpha, beta} is a group of
      # its own, distinct from {alpha} and {beta}. Work packages without any
      # category are grouped under the empty set.
      expect(query_results.work_package_count_by_group)
        .to eql([alpha_category] => 1,
                [alpha_category, beta_category] => 1,
                [beta_category] => 1,
                [] => 1)

      # Group keys are sorted like the work packages themselves
      expect(query_results.work_package_count_by_group.keys)
        .to eql [[alpha_category], [alpha_category, beta_category], [beta_category], []]

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
        create_wp_with_categories("Alpha wp", [alpha_category], estimated_hours: 2)
      end
      let!(:both_categories_wp) do
        create_wp_with_categories("Both categories wp", [beta_category, alpha_category], estimated_hours: 3)
      end

      it "sums per category set" do
        sums = query_results.all_group_sums.transform_values do |by_column|
          by_column.transform_keys(&:name)[:estimated_hours]
        end

        expect(sums)
          .to eq([alpha_category] => 2.0,
                 [alpha_category, beta_category] => 3.0,
                 [beta_category] => nil,
                 [] => nil)
      end
    end
  end

  context "with equally named categories in different projects" do
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

    let(:same_name_category) do
      create(:category, name: alpha_category.name, project: other_project)
    end

    let!(:same_name_wp) do
      create(:work_package, subject: "Same name other project wp", project: other_project).tap do |wp|
        wp.category_ids_replacements = [same_name_category.id]
        wp.save!
      end
    end

    let(:query) do
      build(:query,
            user:,
            group_by: "categories",
            show_hierarchies: false,
            project: nil).tap do |q|
        q.filters.clear
        q.sort_criteria = sort_criteria
      end
    end

    it "keeps the equally named category sets in separate groups" do
      expect(query_results.work_package_count_by_group)
        .to eql([alpha_category] => 1,
                [same_name_category] => 1,
                [alpha_category, beta_category] => 1,
                [beta_category] => 1,
                [] => 1)
    end
  end
end
