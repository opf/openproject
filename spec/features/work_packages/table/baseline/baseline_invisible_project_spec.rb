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

RSpec.describe "baseline with a work package moved to an invisible project", :js,
               with_settings: { date_format: "%Y-%m-%d" } do
  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:visible_project) { create(:project, types: [type_bug]) }
  shared_let(:private_project) { create(:project, types: [type_bug]) }

  shared_let(:user) do
    create(:user,
           firstname: "Itsa",
           lastname: "Me",
           member_with_permissions: { visible_project => %i[view_work_packages edit_work_packages work_package_assigned
                                                            assign_versions] })
  end

  shared_let(:wp_bug) do
    wp = Timecop.travel(5.days.ago) do
      create(:work_package,
             project: visible_project,
             type: type_bug,
             assigned_to: user,
             responsible: user,
             subject: "WP in public project",
             start_date: "2023-05-01",
             due_date: "2023-05-02")
    end

    Timecop.travel(1.hour.ago) do
      WorkPackages::UpdateService
        .new(user: User.system, model: wp)
        .call(
          subject: "Moved to private project",
          project: private_project
        )
        .on_failure { |result| raise result.message }
        .result
    end
  end

  shared_let(:query) do
    query = create(:query,
                   name: "Global query changes since yesterday",
                   project: nil,
                   user:)

    query.timestamps = ["P-1d", "PT0S"]
    query.column_names = %w[id subject status type start_date due_date version priority assigned_to responsible project]
    query.save!(validate: false)

    query
  end

  let(:baseline_modal) { Components::WorkPackages::BaselineModal.new }
  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:baseline) { Components::WorkPackages::Baseline.new }

  current_user { user }

  describe "with EE active", with_ee: %i[baseline_comparison] do
    it "shows the item with all values removed" do
      wp_table.visit_query(query)

      baseline.expect_active
      baseline.expect_removed wp_bug

      baseline.expect_changed_attributes wp_bug,
                                         subject: ["WP in public project", ""],
                                         startDate: ["2023-05-01", ""],
                                         dueDate: ["2023-05-02", ""]
    end
  end
end
