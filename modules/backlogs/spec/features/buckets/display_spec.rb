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
require_relative "../../support/pages/backlog"

RSpec.describe "Backlog bucket display", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:closed_status) { create(:status, is_closed: true) }

  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking backlogs]) }

  shared_let(:bucket_beta) { create(:backlog_bucket, project:, name: "Beta bucket") }
  shared_let(:bucket_alpha) { create(:backlog_bucket, project:, name: "Alpha bucket") }
  shared_let(:bucket_gamma) { create(:backlog_bucket, project:, name: "Gamma bucket") }

  shared_let(:wp_alpha1) { create(:work_package, project:, backlog_bucket: bucket_alpha, position: 1) }
  shared_let(:wp_alpha_closed) do
    create(:work_package, project:, backlog_bucket: bucket_alpha, position: 2, status: closed_status)
  end
  shared_let(:wp_alpha2) { create(:work_package, project:, backlog_bucket: bucket_alpha, position: 3) }
  shared_let(:wp_beta1)  { create(:work_package, project:, backlog_bucket: bucket_beta, position: 1) }
  shared_let(:wp_inbox1) { create(:work_package, project:, backlog_bucket: nil, sprint: nil, position: 1) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user,
           member_with_permissions: {
             project => %i[view_sprints view_work_packages create_sprints manage_sprint_items]
           })
  end

  it "lists buckets alphabetically (inbox at the bottom is not named)" do
    backlogs_page.visit!

    backlogs_page.expect_bucket_names_in_order(
      "Alpha bucket",
      "Beta bucket",
      "Gamma bucket"
    )
  end

  it "shows the work-package count and work packages on populated buckets" do
    backlogs_page.visit!

    backlogs_page.expect_backlog_bucket_work_package_count(bucket_alpha, 2)
    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(bucket_alpha,
                                                                  work_packages: [wp_alpha1, wp_alpha2])
    backlogs_page.expect_backlog_bucket_work_package_count(bucket_beta, 1)
    backlogs_page.expect_work_packages_in_backlog_bucket_in_order(bucket_beta,
                                                                  work_packages: [wp_beta1])
  end

  it "shows the '+ Backlog bucket' button" do
    backlogs_page.visit!

    backlogs_page.expect_new_backlog_bucket_button
  end

  context "without the :create_sprints permission" do
    current_user do
      create(:user,
             member_with_permissions: {
               project => %i[view_sprints view_work_packages manage_sprint_items]
             })
    end

    it "hides the '+ Backlog bucket' button" do
      backlogs_page.visit!

      backlogs_page.expect_no_new_backlog_bucket_button
    end
  end
end
