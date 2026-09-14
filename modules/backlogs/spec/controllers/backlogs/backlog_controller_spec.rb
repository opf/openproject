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

RSpec.describe Backlogs::BacklogController do
  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:type_task) { create(:type_task) }
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:status) { create(:status, name: "status 1", is_default: true) }
  shared_let(:sprint) { create(:sprint, project:) }
  shared_let(:backlog_bucket) { create(:backlog_bucket, project:) }
  shared_let(:inbox_work_package) { create(:work_package, project:, status:) }
  shared_let(:bucket_work_package) { create(:work_package, project:, status:, backlog_bucket:) }
  shared_let(:sprint_work_package) { create(:work_package, project:, status:, sprint:) }

  current_user { user }

  describe "GET #show" do
    let(:params) { {} }

    subject do
      get :show, params: { project_id: project.id }.merge(params), format: :html
    end

    it "loads the backlog page and preserves the backlog menu item", :aggregate_failures do
      subject

      expect(response).to be_successful
      expect(response).to render_template("backlogs/backlog/show")
      expect(assigns(:project)).to eq(project)
      expect(controller.controller_path).to eq("backlogs/backlog")
      expect(controller.action_name).to eq("show")
      expect(controller.current_menu_item).to eq(:backlog)
    end

    context "for turbo frame request with frame id backlogs_container" do
      before { request.headers["Turbo-Frame"] = "backlogs_container" }

      it "renders the backlog_list partial without layout", :aggregate_failures do
        subject

        expect(response).to be_successful
        expect(response).to render_template("backlogs/backlog/_backlog_list")
        expect(response).to render_template(layout: false)
        expect(assigns(:project)).to eq(project)
        expect(assigns(:backlog_buckets)).to match [backlog_bucket]
        expect(assigns(:sprints)).to match [sprint]
        expect(assigns(:work_packages_by_sprint_id)).to eq({ sprint.id => [sprint_work_package] })
        expect(assigns(:work_packages_by_backlog_id)).to eq({ nil => [inbox_work_package],
                                                              backlog_bucket.id => [bucket_work_package] })
      end

      context "when filtering" do
        context "with a work package attribute via params[:filters]" do
          shared_let(:other_status) { create(:status, name: "status 2") }
          shared_let(:other_sprint_work_package) { create(:work_package, project:, status: other_status, sprint:) }
          shared_let(:other_bucket_work_package) { create(:work_package, project:, status: other_status, backlog_bucket:) }

          let(:params) { { filters: "status_id = \"#{status.id}\"" } }

          it "narrows both the sprint and backlog listings", :aggregate_failures do
            subject

            expect(assigns(:work_packages_by_sprint_id)).to eq({ sprint.id => [sprint_work_package] })
            expect(assigns(:work_packages_by_backlog_id)).to eq({ nil => [inbox_work_package],
                                                                  backlog_bucket.id => [bucket_work_package] })
          end
        end

        context "when filtering by the permanent subject search field via params[:filters]" do
          shared_let(:matching_sprint_wp) { create(:work_package, project:, status:, sprint:, subject: "needle in a haystack") }
          shared_let(:matching_bucket_wp) do
            create(:work_package, project:, status:, backlog_bucket:, subject: "needle in a haystack")
          end
          shared_let(:non_matching_sprint_wp) { create(:work_package, project:, status:, sprint:, subject: "unrelated") }
          shared_let(:non_matching_bucket_wp) { create(:work_package, project:, status:, backlog_bucket:, subject: "unrelated") }

          let(:params) { { filters: 'subject ~ "needle"' } }

          it "narrows the sprint and backlog listings to matching subjects", :aggregate_failures do
            subject

            expect(assigns(:work_packages_by_sprint_id)[sprint.id]).to contain_exactly(matching_sprint_wp)
            expect(assigns(:work_packages_by_backlog_id)[backlog_bucket.id]).to contain_exactly(matching_bucket_wp)
          end
        end

        context "with a malformed filters param" do
          let(:params) { { filters: "invalid" } }

          it "ignores it instead of erroring", :aggregate_failures do
            subject

            expect(response).to be_successful
            expect(assigns(:work_packages_by_sprint_id)).to eq({ sprint.id => [sprint_work_package] })
          end
        end

        context "when selecting a specific sprint via sprint_ids" do
          shared_let(:other_sprint) { create(:sprint, project:) }
          shared_let(:other_sprint_work_package) { create(:work_package, project:, status:, sprint: other_sprint) }

          let(:params) { { sprint_ids: [sprint.id] } }

          it "only loads the selected sprint's work packages", :aggregate_failures do
            subject

            expect(assigns(:sprints)).to contain_exactly(sprint)
            expect(assigns(:work_packages_by_sprint_id)).to eq({ sprint.id => [sprint_work_package] })
          end
        end

        context "when selecting both a specific bucket and inbox via bucket_ids" do
          shared_let(:other_bucket) { create(:backlog_bucket, project:) }
          shared_let(:other_bucket_work_package) { create(:work_package, project:, status:, backlog_bucket: other_bucket) }

          let(:params) { { bucket_ids: [backlog_bucket.id.to_s, "inbox"] } }

          it "returns the union of the selected bucket's and the inbox's work packages", :aggregate_failures do
            subject

            expect(assigns(:backlog_buckets)).to contain_exactly(backlog_bucket)
            expect(assigns(:work_packages_by_backlog_id)).to eq({ nil => [inbox_work_package],
                                                                  backlog_bucket.id => [bucket_work_package] })
          end
        end
      end

      context "when a shared sprint's owning project has another active sprint invisible to this project" do
        let(:sharer_project) { create(:project, sprint_sharing: "no_sharing") }
        let(:receiving_project) { create(:project, sprint_sharing: "no_sharing", types: [type_feature, type_task]) }
        let!(:shared_sprint) { create(:sprint, project: sharer_project) }
        let!(:work_package_linking_shared_sprint) do
          create(:work_package, project: receiving_project, type: type_feature, status:, sprint: shared_sprint)
        end
        let!(:invisible_active_sprint) do
          create(:sprint, project: sharer_project, status: "active",
                          start_date: Date.yesterday, finish_date: Date.tomorrow)
        end

        it "includes the invisible active sprint among @active_sprints", :aggregate_failures do
          get :show, params: { project_id: receiving_project.id }, format: :html

          expect(assigns(:sprints)).to contain_exactly(shared_sprint)
          expect(assigns(:sprints)).not_to include(invisible_active_sprint)
          expect(assigns(:active_sprints)).to include(invisible_active_sprint)
        end
      end
    end
  end
end
