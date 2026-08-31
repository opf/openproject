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

RSpec.describe "Backlog quick search and advanced filters", :js do
  create_shared_association_defaults_for_work_package_factory

  shared_let(:project) do
    create(:project, enabled_module_names: %w[work_package_tracking backlogs])
  end

  shared_let(:user) { create(:admin) }

  shared_let(:status_a) { create(:status, name: "Status A", is_default: true) }
  shared_let(:status_b) { create(:status, name: "Status B") }
  shared_let(:bucket) { create(:backlog_bucket, project:) }

  shared_let(:matching_wp) do
    create(:work_package, project:, backlog_bucket: bucket, status: status_a, subject: "Keep the Needle in a haystack")
  end
  shared_let(:other_wp) do
    create(:work_package, project:, backlog_bucket: bucket, status: status_a, subject: "Unrelated subject")
  end
  shared_let(:status_b_wp) do
    create(:work_package, project:, backlog_bucket: bucket, status: status_b, subject: "Keep me but wrong status")
  end
  shared_let(:keep_last_wp) do
    create(:work_package, project:, backlog_bucket: bucket, status: status_a, subject: "Keep last")
  end

  let(:backlogs_page) { Pages::Backlog.new(project) }

  current_user { user }

  before { backlogs_page.visit! }

  it "narrows the listings as the subject quick search is typed" do
    backlogs_page.expect_work_package_in_backlog_bucket(matching_wp, bucket)
    backlogs_page.expect_work_package_in_backlog_bucket(other_wp, bucket)
    backlogs_page.expect_work_package_in_backlog_bucket(status_b_wp, bucket)
    backlogs_page.expect_work_package_in_backlog_bucket(keep_last_wp, bucket)

    backlogs_page.apply_subject_filter("Needle")

    backlogs_page.expect_work_package_in_backlog_bucket(matching_wp, bucket)
    backlogs_page.expect_work_package_not_in_backlog_bucket(other_wp, bucket)
    backlogs_page.expect_work_package_not_in_backlog_bucket(status_b_wp, bucket)
    backlogs_page.expect_work_package_not_in_backlog_bucket(keep_last_wp, bucket)
  end

  it "narrows the listings when an advanced filter is applied" do
    backlogs_page.expect_work_package_in_backlog_bucket(status_b_wp, bucket)

    backlogs_page.apply_status_filter(status_b)

    backlogs_page.expect_work_package_in_backlog_bucket(status_b_wp, bucket)
    backlogs_page.expect_work_package_not_in_backlog_bucket(matching_wp, bucket)
    backlogs_page.expect_work_package_not_in_backlog_bucket(other_wp, bucket)
    backlogs_page.expect_work_package_not_in_backlog_bucket(keep_last_wp, bucket)
  end
end
