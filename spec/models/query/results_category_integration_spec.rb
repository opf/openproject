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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Query::Results, "Filtering, sorting and grouping by categories" do
  let(:project) { create(:project) }
  let(:user) do
    create(:user, member_with_permissions: { project => [:view_work_packages] })
  end

  let(:alpha) { create(:category, name: "Alpha", project:) }
  let(:beta) { create(:category, name: "beta", project:) }

  let(:filter) { nil }
  let(:group_by) { nil }
  let(:sort_criteria) { [] }

  let(:query) do
    build(:query, user:, project:, group_by:, show_hierarchies: false).tap do |q|
      q.filters.clear
      q.add_filter(*filter) if filter
      q.sort_criteria = sort_criteria
    end
  end

  subject(:results) { described_class.new(query) }

  before { login_as(user) }

  context "with multiple categories disabled",
          with_flag: { work_package_multiple_categories: false },
          with_settings: { work_package_multiple_categories: false } do
    let!(:alpha_wp) { create(:work_package, project:, category: alpha) }
    let!(:beta_wp) { create(:work_package, project:, category: beta) }
    let!(:uncategorized_wp) { create(:work_package, project:) }

    describe "filtering" do
      context 'with the "=" operator' do
        let(:filter) { ["category_id", "=", [alpha.id.to_s]] }

        it "returns the work packages with the category" do
          expect(results.work_packages).to contain_exactly(alpha_wp)
        end
      end

      context 'with the "!" operator' do
        let(:filter) { ["category_id", "!", [alpha.id.to_s]] }

        it "returns the work packages without the category, including uncategorized ones" do
          expect(results.work_packages).to contain_exactly(beta_wp, uncategorized_wp)
        end
      end

      context 'with the "*" operator' do
        let(:filter) { ["category_id", "*", []] }

        it "returns the work packages with any category" do
          expect(results.work_packages).to contain_exactly(alpha_wp, beta_wp)
        end
      end

      context 'with the "!*" operator' do
        let(:filter) { ["category_id", "!*", []] }

        it "returns the work packages without a category" do
          expect(results.work_packages).to contain_exactly(uncategorized_wp)
        end
      end
    end

    describe "sorting ASC by category" do
      let(:sort_criteria) { [%w[category asc]] }

      it "sorts case-insensitively by name with uncategorized last" do
        expect(results.work_packages).to eq [alpha_wp, beta_wp, uncategorized_wp]
      end
    end

    describe "sorting DESC by category" do
      let(:sort_criteria) { [%w[category desc]] }

      it "sorts case-insensitively by name with uncategorized first" do
        expect(results.work_packages).to eq [uncategorized_wp, beta_wp, alpha_wp]
      end
    end

    describe "grouping by category" do
      let(:group_by) { "category" }

      it "groups by the category" do
        expect(results.work_package_count_by_group)
          .to eq(alpha => 1, beta => 1, nil => 1)
      end
    end
  end

  context "with multiple categories enabled",
          with_flag: { work_package_multiple_categories: true },
          with_settings: { work_package_multiple_categories: true } do
    let!(:alpha_wp) { create(:work_package, project:, category_ids_replacements: [alpha.id]) }
    let!(:both_wp) { create(:work_package, project:, category_ids_replacements: [beta.id, alpha.id]) }
    let!(:beta_wp) { create(:work_package, project:, category_ids_replacements: [beta.id]) }
    let!(:uncategorized_wp) { create(:work_package, project:) }

    describe "filtering" do
      context 'with the "=" operator' do
        let(:filter) { ["category_id", "=", [beta.id.to_s]] }

        it "returns the work packages having the category among others" do
          expect(results.work_packages).to contain_exactly(both_wp, beta_wp)
        end
      end

      context 'with the "=" operator and multiple values' do
        let(:gamma) { create(:category, name: "Gamma", project:) }
        let!(:gamma_wp) { create(:work_package, project:, category_ids_replacements: [gamma.id]) }

        let(:filter) { ["category_id", "=", [alpha.id.to_s, gamma.id.to_s]] }

        it "returns the work packages having any of the categories, each only once" do
          expect(results.work_packages).to contain_exactly(alpha_wp, both_wp, gamma_wp)
        end
      end

      context 'with the "!" operator' do
        let(:filter) { ["category_id", "!", [beta.id.to_s]] }

        it "returns only the work packages not having the category at all" do
          expect(results.work_packages).to contain_exactly(alpha_wp, uncategorized_wp)
        end
      end

      context 'with the "*" operator' do
        let(:filter) { ["category_id", "*", []] }

        it "returns the work packages with any category, each only once" do
          expect(results.work_packages).to contain_exactly(alpha_wp, both_wp, beta_wp)
        end
      end

      context 'with the "!*" operator' do
        let(:filter) { ["category_id", "!*", []] }

        it "returns the work packages without any category" do
          expect(results.work_packages).to contain_exactly(uncategorized_wp)
        end
      end
    end

    describe "sorting ASC by categories" do
      let(:sort_criteria) { [%w[categories asc]] }

      it "sorts by the aggregated category names with uncategorized last" do
        expect(results.work_packages).to eq [alpha_wp, both_wp, beta_wp, uncategorized_wp]
      end
    end

    describe "sorting DESC by categories" do
      let(:sort_criteria) { [%w[categories desc]] }

      it "sorts by the aggregated category names with uncategorized first" do
        expect(results.work_packages).to eq [uncategorized_wp, beta_wp, both_wp, alpha_wp]
      end
    end

    describe "grouping by categories" do
      let(:group_by) { "categories" }

      it "groups by the set of categories" do
        expect(results.work_package_count_by_group)
          .to eq([alpha] => 1, [alpha, beta] => 1, [beta] => 1, [] => 1)
      end
    end
  end

  context "when filtering at a baseline timestamp" do
    let(:filter) { ["category_id", "=", [alpha.id.to_s]] }

    let!(:formerly_alpha_wp) do
      create(:work_package, project:, category: beta,
                            journals: { 2.days.ago => { category_id: alpha.id }, 1.hour.ago => {} })
    end
    let!(:newly_alpha_wp) do
      create(:work_package, project:, category: alpha,
                            journals: { 2.days.ago => { category_id: beta.id }, 1.hour.ago => {} })
    end

    before { query.timestamps = [Timestamp.parse(1.day.ago.iso8601)] }

    context "with multiple categories disabled",
            with_flag: { work_package_multiple_categories: false },
            with_settings: { work_package_multiple_categories: false } do
      it "matches the category the work packages had at that time" do
        expect(results.work_packages).to contain_exactly(formerly_alpha_wp)
      end
    end

    context "with multiple categories enabled",
            with_flag: { work_package_multiple_categories: true },
            with_settings: { work_package_multiple_categories: true } do
      it "matches the category the work packages had at that time" do
        expect(results.work_packages).to contain_exactly(formerly_alpha_wp)
      end

      context "with a work package that had several categories at that time" do
        let(:filter) { ["category_id", "=", [beta.id.to_s]] }

        let!(:formerly_alpha_and_beta_wp) do
          create(:work_package, project:, category: alpha,
                                journals: { 2.days.ago => { category_ids: [alpha.id, beta.id] }, 1.hour.ago => {} })
        end

        it "matches each of the categories" do
          expect(results.work_packages).to contain_exactly(formerly_alpha_and_beta_wp, newly_alpha_wp)
        end
      end
    end
  end
end
