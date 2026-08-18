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

RSpec.describe "Backlogs collection move", :skip_csrf, type: :rails_request do
  shared_let(:type) { create(:type) }
  shared_let(:project) do
    create(:project, types: [type], enabled_module_names: %i[backlogs work_package_tracking])
  end
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:bucket) { create(:backlog_bucket, project:) }

  let!(:bucket_wp1) { create(:work_package, backlog_bucket: bucket, position: 1, type:, project:) }
  let!(:bucket_wp2) { create(:work_package, backlog_bucket: bucket, position: 2, type:, project:) }
  let!(:sprint_wp1) { create(:work_package, sprint:, position: 1, type:, project:) }

  let(:permissions) { %i[view_work_packages edit_work_packages view_sprints manage_sprint_items] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  current_user { user }

  def move_collection(ids:, **params)
    put move_project_backlogs_work_packages_path(project),
        params: { ids:, **params },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
  end

  context "without the manage_sprint_items permission" do
    let(:permissions) { %i[view_work_packages edit_work_packages view_sprints] }

    it "forbids the request" do
      move_collection(ids: [bucket_wp1.id], list_type: "sprint", list_id: sprint.id)

      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when the backlogs module is disabled" do
    before { project.enabled_module_names -= ["backlogs"] }

    it "does not route to the action" do
      move_collection(ids: [bucket_wp1.id], list_type: "sprint", list_id: sprint.id)

      expect(response).to have_http_status(:forbidden)
    end
  end

  shared_examples "rejects the whole request" do |status: :unprocessable_entity|
    it "rejects without moving anything", :aggregate_failures do
      positions_before = WorkPackage.order(:id).pluck(:id, :sprint_id, :backlog_bucket_id, :position)

      subject

      expect(response).to have_http_status(status)
      expect(WorkPackage.order(:id).pluck(:id, :sprint_id, :backlog_bucket_id, :position))
        .to eq(positions_before)
    end
  end

  describe "parameter validation" do
    context "without an ids parameter" do
      subject do
        put move_project_backlogs_work_packages_path(project),
            params: { list_type: "sprint", list_id: sprint.id },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      it_behaves_like "rejects the whole request", status: :bad_request
    end

    context "with a blank id" do
      subject { move_collection(ids: [bucket_wp1.id, ""], list_type: "sprint", list_id: sprint.id) }

      it_behaves_like "rejects the whole request"
    end

    context "with duplicate ids" do
      subject { move_collection(ids: [bucket_wp1.id, bucket_wp1.id], list_type: "sprint", list_id: sprint.id) }

      it_behaves_like "rejects the whole request"
    end

    context "with an id from another project" do
      let!(:other_wp) { create(:work_package) }

      subject { move_collection(ids: [bucket_wp1.id, other_wp.id], list_type: "sprint", list_id: sprint.id) }

      it_behaves_like "rejects the whole request"
    end

    context "with an id of a work package the user cannot see" do
      let!(:invisible_wp) { create(:work_package, project: create(:project)) }

      subject { move_collection(ids: [invisible_wp.id], list_type: "sprint", list_id: sprint.id) }

      it_behaves_like "rejects the whole request"
    end

    context "with more ids than the batch cap" do
      # Synthetic ids: the cap must fire before any of them reach the
      # database lookup.
      subject do
        move_collection(ids: Array.new(Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE + 1) { |i| (i + 1).to_s },
                        list_type: "sprint", list_id: sprint.id)
      end

      it_behaves_like "rejects the whole request"

      it "names the cap in the rejection" do
        subject

        expect(response.body).to include(
          ERB::Util.html_escape(
            I18n.t("backlogs.work_packages.move_collection.too_many_work_packages",
                   max: Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE)
          )
        )
      end
    end
  end

  describe "successful moves" do
    context "with an optimistic same-list reorder whose block is honored" do
      it "responds with the moved event only, no frame reload", :aggregate_failures do
        move_collection(ids: [sprint_wp1.id], list_type: "sprint", list_id: sprint.id,
                        prev_id: "", optimistic: true)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("backlogs:work-package-moved")
        expect(response.body).to include("work_package_ids")
        expect(response.body).not_to include('target="backlogs_container"')
      end
    end

    context "with a cross-list batch" do
      it "reloads the backlogs frame and emits the ordered batch event", :aggregate_failures do
        move_collection(ids: [bucket_wp1.id, bucket_wp2.id], list_type: "sprint", list_id: sprint.id,
                        prev_id: sprint_wp1.id, optimistic: true)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('target="backlogs_container"')
        expect(response.body).to include("work_package_ids")
        expect(sprint.work_packages_for(project).pluck(:id))
          .to eq [sprint_wp1.id, bucket_wp1.id, bucket_wp2.id]
      end
    end

    context "with an optimistic downward same-list block whose placement is honored" do
      let!(:sprint_wp2) { create(:work_package, sprint:, position: 2, type:, project:) }
      let!(:sprint_wp3) { create(:work_package, sprint:, position: 3, type:, project:) }

      it "responds with the moved event only, no frame reload", :aggregate_failures do
        move_collection(ids: [sprint_wp1.id, sprint_wp2.id], list_type: "sprint", list_id: sprint.id,
                        prev_id: sprint_wp3.id, optimistic: true)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("work_package_ids")
        expect(response.body).not_to include('target="backlogs_container"')
        expect(sprint.work_packages_for(project).pluck(:id)).to eq [sprint_wp3.id, sprint_wp1.id, sprint_wp2.id]
        expect(sprint.work_packages_for(project).pluck(:position)).to eq [1, 2, 3]
      end
    end

    context "when the persisted block diverges from the request" do
      it "reloads instead of skipping" do
        # An append has no prev_id for the anchor check to hold against, so
        # the optimistic placement is unverifiable and must reconcile.
        move_collection(ids: [sprint_wp1.id], list_type: "sprint", list_id: sprint.id,
                        optimistic: true)

        expect(response.body).to include('target="backlogs_container"')
      end
    end
  end

  describe "failed moves" do
    let!(:sprint_wp2) { create(:work_package, sprint:, position: 2, type:, project:) }
    let!(:sprint_wp3) { create(:work_package, sprint:, position: 3, type:, project:) }

    it "streams an error flash and a 422 without moving anything" do
      move_collection(ids: [sprint_wp2.id], list_type: "sprint", list_id: sprint.id,
                      prev_id: bucket_wp1.id, optimistic: true)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(
        ERB::Util.html_escape(I18n.t("backlogs.work_packages.batch_update_service.stale_predecessor"))
      )
      expect(sprint.work_packages_for(project).pluck(:id))
        .to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end

    it "streams an error flash and a 422 for a same-list reorder into a completed sprint" do
      sprint.update!(status: "completed")

      move_collection(ids: [sprint_wp2.id], list_type: "sprint", list_id: sprint.id,
                      prev_id: sprint_wp3.id, optimistic: true)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include(
        ERB::Util.html_escape(I18n.t("backlogs.work_packages.batch_update_service.unavailable_target"))
      )
      expect(sprint.work_packages_for(project).pluck(:id))
        .to eq [sprint_wp1.id, sprint_wp2.id, sprint_wp3.id]
    end
  end

  describe "invisibility after move" do
    # Moving into a sprint short-circuits the type/status exclusion check
    # (work_package_invisible_after_move? only applies it to backlog
    # destinations), so the target here is the bucket.
    let(:excluded_type) { create(:type) }

    before do
      project.project_types.create!(type: excluded_type)
      project.backlog_excluded_types << excluded_type
    end

    context "when only the second moved member becomes invisible" do
      let!(:hidden_member) { create(:work_package, sprint:, position: 2, type: excluded_type, project:) }

      it "flashes the singular invisible-after-move notice" do
        move_collection(ids: [sprint_wp1.id, hidden_member.id], list_type: "backlog_bucket", list_id: bucket.id,
                        prev_id: bucket_wp2.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          ERB::Util.html_escape(I18n.t(:notice_work_package_invisible_after_move, count: 1, backlog: bucket.name))
        )
      end
    end

    context "when every moved member stays visible" do
      let!(:visible_member) { create(:work_package, sprint:, position: 2, type:, project:) }

      it "does not flash" do
        move_collection(ids: [sprint_wp1.id, visible_member.id], list_type: "backlog_bucket", list_id: bucket.id,
                        prev_id: bucket_wp2.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(
          ERB::Util.html_escape(I18n.t(:notice_work_package_invisible_after_move, count: 1, backlog: bucket.name))
        )
      end
    end

    context "when more than one moved member becomes invisible" do
      let!(:hidden_member1) { create(:work_package, sprint:, position: 2, type: excluded_type, project:) }
      let!(:hidden_member2) { create(:work_package, sprint:, position: 3, type: excluded_type, project:) }

      it "flashes the plural invisible-after-move notice" do
        move_collection(ids: [hidden_member1.id, hidden_member2.id], list_type: "backlog_bucket", list_id: bucket.id,
                        prev_id: bucket_wp2.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(
          ERB::Util.html_escape(
            I18n.t(:notice_work_package_invisible_after_move, count: 2, backlog: bucket.name)
          )
        )
      end
    end
  end
end
