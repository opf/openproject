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

RSpec.describe WorkPackagesController do
  before do
    login_as current_user
  end

  let(:stub_project) { build_stubbed(:project, identifier: "test_project", public: false) }
  let(:current_user) { build_stubbed(:user) }
  let(:work_packages) { [build_stubbed(:work_package)] }

  describe "index" do
    let(:query) do
      build_stubbed(:query)
    end

    before do
      mock_permissions_for(User.current, &:allow_everything)
      allow(controller).to receive(:retrieve_query).and_return(query)
    end

    describe "bcf" do
      let(:mime_type) { "bcf" }
      let(:export_storage) { build_stubbed(:work_packages_export) }

      before do
        service_instance = double("service_instance")

        allow(WorkPackages::Exports::ScheduleService)
          .to receive(:new)
          .with(user: current_user)
          .and_return(service_instance)

        allow(service_instance)
          .to receive(:call)
          .with(query:, mime_type: mime_type.to_sym, params: anything)
          .and_return(ServiceResult.failure(result: "uuid of the export job"))
      end

      it "redirects to the export" do
        get "index", params: { format: "bcf" }
        expect(response).to redirect_to job_status_path("uuid of the export job")
      end

      context "with json accept" do
        it "fulfills the defined should_receives" do
          request.headers["Accept"] = "application/json"
          get "index", params: { format: "bcf" }
          expect(response.body).to eq({ job_id: "uuid of the export job" }.to_json)
        end
      end
    end
  end
end
