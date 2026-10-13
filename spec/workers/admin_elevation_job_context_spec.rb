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

RSpec.describe AdminElevationJobContext, with_flag: { admin_privilege_elevation: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:other_admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  let(:job_class) do
    Class.new(ApplicationJob) do
      class << self
        attr_accessor :elevated, :nested_job_data
      end

      def perform(user_id, project_id, enqueue_nested: false)
        self.class.elevated = User.find(user_id).admin_in_project?(Project.find(project_id))
        self.class.nested_job_data = self.class.new(user_id, project_id).serialize if enqueue_nested
      end
    end
  end

  let(:enqueuing_user) { admin }
  let(:elevation) { Users::AdminElevation.in_projects([project.id]) }

  before do
    stub_const("AdminElevationContextTestJob", job_class)
    enqueuing_user.admin_elevation = elevation
  end

  after do
    enqueuing_user.admin_elevation = nil
  end

  def enqueue(user_id: admin.id, **)
    User.execute_as(enqueuing_user) { AdminElevationContextTestJob.new(user_id, project.id, **).serialize }
  end

  def run_on_worker(job_data)
    ActiveJob::Base.execute(job_data)
    AdminElevationContextTestJob.elevated
  end

  it "keeps the elevation of the admin enqueuing the job" do
    expect(run_on_worker(enqueue)).to be true
  end

  it "does not hand the elevation to another user in the job" do
    expect(run_on_worker(enqueue(user_id: other_admin.id))).to be false
  end

  it "does not leave the elevation in the request store after the job" do
    run_on_worker(enqueue)

    expect(RequestStore.store).not_to have_key(:admin_elevations)
  end

  it "keeps the elevation when the job is performed right away" do
    job = User.execute_as(admin) { AdminElevationContextTestJob.new(admin.id, project.id) }
    job.perform_now

    expect(AdminElevationContextTestJob.elevated).to be true
  end

  it "passes the elevation on to jobs enqueued by the job" do
    run_on_worker(enqueue(enqueue_nested: true))

    expect(run_on_worker(AdminElevationContextTestJob.nested_job_data)).to be true
  end

  context "for an admin elevated everywhere" do
    let(:elevation) { Users::AdminElevation.everywhere }

    it "keeps the elevation everywhere" do
      expect(run_on_worker(enqueue)).to be true
    end
  end

  context "for an admin that is not elevated" do
    let(:elevation) { Users::AdminElevation.none }

    it "is not elevated in the job" do
      expect(run_on_worker(enqueue)).to be false
    end
  end

  context "for a regular user enqueuing the job" do
    let(:enqueuing_user) { create(:user) }

    it "captures no elevation" do
      expect(enqueue["admin_elevation"]).to be_nil
    end
  end
end
