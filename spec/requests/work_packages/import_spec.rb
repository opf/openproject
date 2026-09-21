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

RSpec.describe "Work package CSV import", :skip_csrf, type: :rails_request do
  shared_let(:type) { create(:type_task, name: "Task") }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:importer_role) do
    create(:project_role, permissions: %i[view_work_packages add_work_packages import_work_packages])
  end
  shared_let(:plain_role) { create(:project_role, permissions: %i[view_work_packages add_work_packages]) }
  shared_let(:importer) { create(:user, member_with_roles: { project => importer_role }) }
  shared_let(:member) { create(:user, member_with_roles: { project => plain_role }) }
  shared_let(:outsider) { create(:user) }
  shared_let(:admin) { create(:admin) }

  let(:show_path) { import_project_work_packages_path(project) }
  let(:csv_fixture) { Rails.root.join("spec/fixtures/csv_import/work_packages.csv") }
  let(:template_path) { import_template_project_work_packages_path(project) }

  describe "with the flag on", with_flag: { csv_import: true } do
    context "as a member holding the permission" do
      before { login_as importer }

      it "renders the page" do
        get show_path

        expect(response).to have_http_status(:ok)
      end

      it "serves the template" do
        get template_path

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/csv")
      end

      it "accepts an upload" do
        post show_path, params: { file: Rack::Test::UploadedFile.new(csv_fixture, "text/csv") }

        expect(response).to redirect_to(/#{Regexp.escape(show_path)}/)
      end

      describe "the dry run flag" do
        def upload(params)
          post show_path,
               params: params.merge(file: Rack::Test::UploadedFile.new(csv_fixture, "text/csv"))
        end

        it "checks the file when the box is ticked" do
          upload(dry_run: "1")

          expect(WorkPackages::Import::CSV::CsvImportJob)
            .to have_been_enqueued.with(hash_including(dry_run: true))
        end

        it "imports when the box is cleared" do
          upload(dry_run: "0")

          expect(WorkPackages::Import::CSV::CsvImportJob)
            .to have_been_enqueued.with(hash_including(dry_run: false))
        end

        it "checks rather than imports when the parameter is missing" do
          upload({})

          expect(WorkPackages::Import::CSV::CsvImportJob)
            .to have_been_enqueued.with(hash_including(dry_run: true))
        end
      end
    end

    context "as an administrator" do
      before { login_as admin }

      it "renders the page" do
        get show_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "as a member without the permission" do
      before { login_as member }

      it "refuses the page" do
        get show_path

        expect(response).to have_http_status(:forbidden)
      end

      it "refuses the template" do
        get template_path

        expect(response).to have_http_status(:forbidden)
      end

      it "refuses an upload" do
        post show_path

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as a non-member" do
      before { login_as outsider }

      it "refuses the page" do
        get show_path

        expect(response).to have_http_status(:not_found)
      end
    end

    context "as an anonymous visitor" do
      it "asks for a login" do
        get show_path

        expect(response).to redirect_to(signin_path(back_url: import_project_work_packages_url(project)))
      end
    end
  end

  describe "with the flag off", with_flag: { csv_import: false } do
    before { login_as admin }

    # An unmatched route surfaces as a routing error or as a rendered 404 depending on the path;
    # either way it never reaches the controller, which is what the flag is for.
    def unrouted?
      yield
      response.not_found?
    rescue ActionController::RoutingError
      true
    end

    it "does not route the page" do
      expect(unrouted? { get show_path }).to be(true)
    end

    it "does not route the template" do
      expect(unrouted? { get template_path }).to be(true)
    end

    it "does not route an upload" do
      expect(unrouted? { post show_path }).to be(true)
    end
  end

  describe "the template", with_flag: { csv_import: true } do
    before { login_as importer }

    it "sends what the template builder produced, named for download" do
      get template_path

      expect(response.body).to eq(WorkPackages::Import::CSV::Template.call(project:))
      expect(response.headers["Content-Disposition"])
        .to include(WorkPackages::Import::CSV::Template::FILENAME)
    end
  end
end
