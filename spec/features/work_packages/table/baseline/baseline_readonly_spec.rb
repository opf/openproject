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

RSpec.describe "baseline readonly mode", :js, with_ee: %i[baseline_comparison] do
  shared_let(:project) { create(:project) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] })
  end
  shared_let(:work_package) do
    Timecop.travel(10.days.ago) do
      create(:work_package, project:)
    end
  end

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:baseline) { Components::WorkPackages::Baseline.new }
  let(:baseline_modal) { Components::WorkPackages::BaselineModal.new }

  let(:query) do
    create(:query, project:, user:, timestamps:, column_names: %w[id subject])
  end

  current_user { user }

  def subject_field = wp_table.edit_field(work_package, :subject)

  context "when comparing two dates in the past" do
    let(:timestamps) { ["P-5d", "P-2d"] }

    it "renders the table readonly" do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(work_package)
      baseline.expect_active

      subject_field.expect_read_only
    end
  end

  context "when comparing to the current state" do
    let(:timestamps) { ["P-2d", "PT0S"] }

    it "keeps the table editable and turns it readonly when switching to two dates" do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(work_package)
      baseline.expect_active

      subject_field.expect_editable

      baseline_modal.toggle_drop_modal
      baseline_modal.expect_open
      baseline_modal.select_filter "between two specific dates"
      baseline_modal.set_between_dates from: 5.days.ago, from_time: "12:34", to: 2.days.ago, to_time: "12:34"
      baseline_modal.apply

      loading_indicator_saveguard
      wp_table.expect_work_package_listed(work_package)
      baseline.expect_active

      subject_field.expect_read_only
    end
  end
end
