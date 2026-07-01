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

require "rails_helper"

RSpec.describe Backlogs::BacklogComponent, type: :component do
  shared_let(:default_status) { create(:default_status) }
  shared_let(:closed_status) { create(:status, is_closed: true) }
  shared_let(:project) { create(:project) }
  shared_let(:bucket) { create(:backlog_bucket, project:) }
  shared_let(:buckets) { BacklogBucket.for_project(project) }
  shared_let(:user) { create(:admin) }

  current_user { user }

  let(:work_packages_by_backlog_id) do
    WorkPackage.in_backlog_for(project:).group_by(&:backlog_bucket_id)
  end

  def render_component
    render_inline described_class.new(work_packages_by_backlog_id:, buckets:, project:, current_user:)
  end

  describe "total counter" do
    context "when buckets contain only open work packages" do
      let!(:work_packages) do
        create_list(:work_package, 2, project:, backlog_bucket: bucket, status: default_status)
      end

      it "counts all bucket work packages" do
        render_component
        expect(page).to have_css(".Counter", text: "2")
      end
    end

    context "when buckets contain a mix of open and closed work packages" do
      let!(:open_wp) do
        create(:work_package, project:, backlog_bucket: bucket, status: default_status)
      end

      let!(:closed_wp) do
        create(:work_package, project:, backlog_bucket: bucket, status: closed_status)
      end

      it "counts only displayed (non-closed) work packages" do
        render_component
        expect(page).to have_css(".Counter", text: "1")
      end
    end

    context "when a bucket filter is active" do
      shared_let(:bucket_a) { create(:backlog_bucket, project:) }
      shared_let(:bucket_b) { create(:backlog_bucket, project:) }

      let!(:wps_in_bucket_a) do
        create_list(:work_package, 2, project:, backlog_bucket: bucket_a, status: default_status)
      end
      let!(:wps_in_bucket_b) do
        create_list(:work_package, 3, project:, backlog_bucket: bucket_b, status: default_status)
      end
      let!(:inbox_wps) { create_list(:work_package, 1, project:, backlog_bucket: nil, status: default_status) }

      # Simulate the controller: work_packages_by_backlog_id loads all buckets unfiltered,
      # while buckets is the filtered subset.
      let(:buckets) { BacklogBucket.where(id: bucket_a.id) }

      it "counts only work packages in the visible buckets" do
        render_component
        expect(page).to have_css(".Counter", text: "2")
      end
    end

    context "when a bucket filter and the inbox is active" do
      shared_let(:bucket_a) { create(:backlog_bucket, project:) }
      shared_let(:bucket_b) { create(:backlog_bucket, project:) }

      let!(:wps_in_bucket_a) { create_list(:work_package, 2, project:, backlog_bucket: bucket_a, status: default_status) }
      let!(:wps_in_bucket_b) { create_list(:work_package, 3, project:, backlog_bucket: bucket_b, status: default_status) }
      let!(:inbox_wps) { create_list(:work_package, 1, project:, backlog_bucket: nil, status: default_status) }

      let(:buckets) { BacklogBucket.where(id: bucket_a.id) }

      it "counts work packages in the visible bucket and the inbox" do
        render_component
        expect(page).to have_css(".Counter", text: "3")
      end
    end

    context "when the inbox is active" do
      let!(:inbox_wps) { create_list(:work_package, 4, project:, backlog_bucket: nil, status: default_status) }
      let!(:wps_in_bucket) { create_list(:work_package, 2, project:, backlog_bucket: bucket, status: default_status) }

      let(:buckets) { BacklogBucket.none }

      it "counts only inbox work packages" do
        render_component
        expect(page).to have_css(".Counter", text: "4")
      end
    end
  end
end
