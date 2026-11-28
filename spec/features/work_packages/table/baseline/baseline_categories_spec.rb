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

RSpec.describe "baseline rendering of the categories column",
               :js,
               with_ee: %i[baseline_comparison],
               with_flag: { work_package_multiple_categories: true },
               with_settings: { work_package_multiple_categories: true } do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages] })
  end

  shared_let(:backend) { create(:category, project:, name: "Backend") }
  shared_let(:design) { create(:category, project:, name: "Design") }
  shared_let(:frontend) { create(:category, project:, name: "Frontend") }

  shared_let(:recategorized_wp) do
    create(:work_package,
           project:,
           subject: "Recategorized",
           category_ids_replacements: [design.id, frontend.id],
           journals: { 5.days.ago => { category_ids: [backend.id, design.id] }, 1.day.ago => {} })
  end
  shared_let(:unchanged_wp) do
    create(:work_package,
           project:,
           subject: "Unchanged",
           category_ids_replacements: [backend.id],
           journals: { 5.days.ago => {} })
  end

  let(:query) do
    create(:query, name: "Timestamps Query", project:, user:, column_names: %w[id subject categories]).tap do |query|
      query.timestamps = ["P-2d", "PT0S"]
      query.save!(validate: false)
    end
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:baseline) { Components::WorkPackages::Baseline.new }

  current_user { user }

  it "shows the categories the work package had at the baseline" do
    wp_table.visit_query(query)
    wp_table.expect_work_package_listed recategorized_wp, unchanged_wp

    baseline.expect_active
    baseline.expect_changed recategorized_wp
    baseline.expect_unchanged unchanged_wp

    baseline.expect_changed_attributes recategorized_wp,
                                       categories: ["Backend, Design", "Design, Frontend"]

    expect(wp_table.table_container)
      .to have_no_element(:span, title: I18n.t("js.work_packages.baseline.column_incompatible"))
  end
end
