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

RSpec.describe "Backlog bucket deletion", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end
  shared_let(:bucket) { create(:backlog_bucket, project:, name: "Deprecated bucket") }

  shared_let(:inbox_wp1) { create(:work_package, project:) }
  shared_let(:inbox_wp2) { create(:work_package, project:) }

  shared_let(:bucket_wp1) { create(:work_package, project:, backlog_bucket: bucket) }
  shared_let(:bucket_wp2) { create(:work_package, project:, backlog_bucket: bucket) }

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user do
    create(:user,
           member_with_permissions: {
             project => %i[view_sprints view_work_packages create_sprints]
           })
  end

  it "deletes the bucket and moves its work packages to the Inbox" do
    backlogs_page.visit!
    backlogs_page.expect_bucket_names_in_order("Deprecated bucket")

    backlogs_page.click_in_backlog_bucket_menu(bucket, "Delete backlog bucket")

    backlogs_page.expect_and_confirm_backlog_bucket_delete_modal

    expect_and_dismiss_flash type: :success, exact_message: "Successful deletion."
    backlogs_page.expect_no_backlog_bucket(bucket)

    backlogs_page.expect_work_packages_in_inbox_in_order(work_packages: [inbox_wp1, inbox_wp2, bucket_wp1, bucket_wp2])

    expect(BacklogBucket.where(id: bucket.id)).to be_empty
    expect(bucket_wp1.reload.backlog_bucket_id).to be_nil
    expect(bucket_wp2.reload.backlog_bucket_id).to be_nil
  end

  context "without the :create_sprints permission" do
    current_user do
      create(:user,
             member_with_permissions: {
               project => %i[view_sprints view_work_packages]
             })
    end

    it "does not expose the delete action" do
      backlogs_page.visit!

      backlogs_page.expect_no_backlog_bucket_menu(bucket)
    end
  end
end
