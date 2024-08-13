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

RSpec.describe WorkPackagesController, type: :controller do
  before do
    login_as current_user
  end

  let(:project) { create(:project, identifier: "test_project", public: false) }
  let(:stub_project) { build_stubbed(:project, identifier: "test_project", public: false) }
  let(:type) { build_stubbed(:type) }
  let(:stub_work_package) do
    build_stubbed(:work_package,
                  id: 1337,
                  type:,
                  project: stub_project)
  end

  let(:current_user) { create(:user) }

  def self.requires_export_permission(&)
    describe "with the export permission " \
             "without a project" do
      let(:project) { nil }

      before do
        mock_permissions_for(User.current) do |mock|
          mock.allow_in_project :export_work_packages, project: build_stubbed(:project) # any project
        end
      end

      instance_eval(&)
    end

    describe "with the export permission " \
             "with a project" do
      before do
        params[:project_id] = project.id

        mock_permissions_for(User.current) do |mock|
          mock.allow_in_project :export_work_packages, project:
        end
      end

      instance_eval(&)
    end

    describe "without the export permission" do
      let(:project) { nil }

      before do
        mock_permissions_for(User.current, &:forbid_everything)

        call_action
      end

      it "renders a 403" do
        expect(response.response_code).to eq(403)
      end
    end
  end

  describe "index" do
    let(:query) { build_stubbed(:query).tap(&:add_default_filter) }
    let(:work_packages) { double("work packages").as_null_object }
    let(:results) { double("results").as_null_object }

    before do
      mock_permissions_for(User.current) do |mock|
        mock.allow_in_project(:view_work_packages, project:) if project
      end
    end

    describe "with valid query" do
      before do
        allow(controller).to receive(:retrieve_query).and_return(query)
      end

      describe "xls" do
        let(:params) { {} }
        let(:call_action) { get("index", params: params.merge(format: mime_type)) }
        let(:mime_type) { "xls" }
        let(:export_result) { "uuid of the job" }

        requires_export_permission do
          before do
            service_instance = double("service_instance")

            allow(WorkPackages::Exports::ScheduleService)
              .to receive(:new)
                    .with(user: current_user)
                    .and_return(service_instance)

            allow(service_instance)
              .to receive(:call)
              .with(query:, mime_type: mime_type.to_sym, params: anything)
              .and_return(ServiceResult.failure(result: export_result))
          end

          it "fulfills the defined should_receives" do
            call_action

            expect(response).to redirect_to job_status_path("uuid of the job")
          end

          context "with json accept" do
            it "fulfills the defined should_receives" do
              request.headers["Accept"] = "application/json"
              call_action
              expect(response.body).to eq({ job_id: "uuid of the job" }.to_json)
            end
          end
        end
      end
    end
  end
end
