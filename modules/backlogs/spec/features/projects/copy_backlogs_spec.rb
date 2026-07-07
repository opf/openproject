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

RSpec.describe "Project copy with sprints and buckets", :js,
               with_good_job_batches: [CopyProjectJob,
                                       Storages::CopyProjectFoldersJob,
                                       SendCopyProjectStatusEmailJob] do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type) }
  shared_let(:project) do
    create(:project,
           enabled_module_names: %w[work_package_tracking backlogs],
           types: [type])
  end
  shared_let(:sprint) { create(:sprint, project:, name: "Sprint A") }
  shared_let(:bucket) { create(:backlog_bucket, project:, name: "Bucket A") }
  shared_let(:work_package) do
    create(:work_package, project:, type:, subject: "Sprint story", sprint:)
  end
  shared_let(:bucket_work_package) do
    create(:work_package, project:, type:, subject: "Bucket story", backlog_bucket: bucket)
  end

  let(:general_settings_page) { Pages::Projects::Settings::General.new(project) }

  before do
    # Clear jobs enqueued during object creation so they don't interfere with the copy.
    clear_enqueued_jobs
    clear_performed_jobs

    login_as admin
  end

  it "assigns copied work packages to the copied sprint and bucket, not the source ones" do
    general_settings_page.visit!
    general_settings_page.click_copy_action

    expect(page).to have_heading "Copy project \"#{project.name}\""

    fill_in "Name", with: "Copied project"
    click_on "Copy"

    wait_for_copy_to_finish

    copied_project = Project.find_by(name: "Copied project")
    expect(copied_project).to be_present

    copied_sprint = copied_project.sprints.find_by(name: "Sprint A")
    expect(copied_sprint).to be_present
    expect(copied_sprint.id).not_to eq(sprint.id)

    copied_work_package = copied_project.work_packages.find_by(subject: "Sprint story")
    expect(copied_work_package.sprint).to eq(copied_sprint)

    copied_bucket = copied_project.backlog_buckets.find_by(name: "Bucket A")
    expect(copied_bucket).to be_present
    expect(copied_bucket.id).not_to eq(bucket.id)

    copied_bucket_work_package = copied_project.work_packages.find_by(subject: "Bucket story")
    expect(copied_bucket_work_package.backlog_bucket).to eq(copied_bucket)
  end

  def wait_for_copy_to_finish
    expect(page).to have_dialog "Background job status"

    within_dialog "Background job status" do
      expect(page).to have_heading "Copy project"
      expect(page).to have_text "The job has been queued and will be processed shortly."
    end

    # Ensure all jobs are run, especially emails which might be sent later on.
    GoodJob.perform_inline
  end
end
