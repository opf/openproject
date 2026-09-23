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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "rails_helper"

RSpec.describe "Work package CSV import", :skip_csrf, type: :rails_request do
  shared_let(:type) { create(:type_task, name: "Task") }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:default_status) { create(:default_status, name: "New") }
  shared_let(:default_priority) { create(:default_priority, name: "Normal") }
  shared_let(:importer_role) do
    create(:project_role, permissions: %i[view_work_packages add_work_packages import_work_packages])
  end
  shared_let(:plain_role) { create(:project_role, permissions: %i[view_work_packages add_work_packages]) }
  shared_let(:importer) { create(:user, member_with_roles: { project => importer_role }) }
  shared_let(:member) { create(:user, member_with_roles: { project => plain_role }) }
  shared_let(:outsider) { create(:user) }
  shared_let(:admin) { create(:admin) }

  def show_path(**) = import_project_work_packages_path(project, **)
  def status_path(**) = import_status_project_work_packages_path(project, **)

  def page = Capybara.string(response.body)

  def field_error = page.find("[data-test-selector='import-file-error']").text.squish
  let(:csv_fixture) { Rails.root.join("spec/fixtures/csv_import/work_packages.csv") }
  let(:template_path) { import_template_project_work_packages_path(project) }

  describe "who can reach it" do
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

      # Turbo asks for a stream first when it follows the redirect out of #create. Answering that
      # with streams would leave the address bar on the bare page, and a reload would lose the run.
      it "stays a page when Turbo would rather have a stream, so the job survives a reload" do
        get show_path, headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

        expect(response.media_type).to eq("text/html")
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

      it "refuses the poll" do
        get status_path

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

  describe "the page" do
    before { login_as importer }

    it "offers the form, the guidance and an empty report region" do
      get show_path

      expect(response.body).to include("Before you start")
      expect(response.body).to include('accept="text/csv,.csv"')
      expect(page).to have_css("[data-test-selector='import-drop-box']")
      expect(page).to have_text("Drop a CSV file here or click to select one.")
      expect(page).to have_css("#import_report", visible: :all)
      expect(page).to have_css("#import_form", visible: :all)
      expect(response.body).to include("Check file")
    end

    # Submitting an empty form only earns a round trip and a "choose a file" message, so the
    # button waits for the drop zone to hold something. The controller enables it on change.
    it "keeps the submit disabled until a file is chosen" do
      get show_path

      expect(page).to have_button("Check file", disabled: true)
    end

    it "answers Clear with the bare page as a stream, so nothing else is torn down" do
      get status_path

      expect(response.body).to include('target="import_report"')
      expect(response.body).to include('target="import_form"')
      expect(response.body).to include("Before you start")
      expect(response.body).to include("import-drop-box")
      expect(response.body).not_to include('target="poll"')
    end

    it "does not poll when there is no run to watch" do
      get show_path

      expect(page).to have_no_css("[data-work-packages--csv-import-target='poll']", visible: :all)
      expect(response.body).not_to include("csv-import-url-value")
    end

    it "ticks the dry run box, so the first press checks rather than imports" do
      get show_path

      expect(page).to have_field("dry_run", type: "checkbox", checked: true)
    end

    context "when a run is in flight" do
      let(:job_id) { SecureRandom.uuid }

      before do
        create(:delayed_job_status,
          job_id:,
          user: importer,
          status: :in_process,
          payload: { "project_id" => project.id, "filename" => "sprint-43.csv",
            "dry_run" => true })
      end

      it "marks itself for polling and names the file" do
        get show_path(job: job_id)

        expect(page).to have_css("[data-work-packages--csv-import-target='poll']", visible: :all)
        expect(response.body).to include("Checking sprint-43.csv")
        expect(response.body).to include("runs in the background")
      end

      # The address rides on the marker so the two cannot drift: a stale or empty one resolves
      # against <base href="/"> and polls the homescreen, which has no turbo_stream template.
      it "gives the poller the address on the marker itself" do
        get show_path(job: job_id)

        marker = page.find("[data-work-packages--csv-import-target='poll']", visible: :all)

        expect(marker["data-url"]).to eq(status_path(job: job_id))
      end

      it "answers a poll with both regions, so the form never contradicts the report" do
        get status_path(job: job_id)

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include('target="import_report"')
        expect(response.body).to include('target="import_form"')
      end

      it "hides the drop zone and the checkbox while the run is under way" do
        get show_path(job: job_id)

        expect(page).to have_no_css("[data-test-selector='import-drop-box']")
        expect(page).to have_no_field("dry_run", type: "checkbox")
      end

      it "takes the form away, so the same file cannot be sent twice" do
        get show_path(job: job_id)

        expect(page).to have_no_button("Check file")
        expect(page).to have_no_button("Checking...")
      end

      it "shows the bare form for somebody else's job" do
        login_as create(:admin)

        get show_path(job: job_id)

        expect(response.body).not_to include("import_report\" src")
      end

      it "shows the bare form for a job belonging to another project" do
        other = create(:project)
        create(:project_role, permissions: %i[view_work_packages add_work_packages import_work_packages])

        get import_project_work_packages_path(other, job: job_id)

        expect(response).to have_http_status(:not_found).or have_http_status(:forbidden)
      end

      it "shows the bare form for a job that has expired" do
        get show_path(job: SecureRandom.uuid)

        expect(response.body).not_to include("import_report\" src")
        expect(response.body).to include("Check file")
      end
    end

    context "when the run died without reporting" do
      let(:job_id) { SecureRandom.uuid }

      def stopped(status)
        create(:delayed_job_status,
          job_id:,
          user: importer,
          status:,
          payload: { "project_id" => project.id, "filename" => "sprint-43.csv",
            "dry_run" => true })
      end

      it "says so rather than watching a run that is over" do
        stopped(:failure)

        get show_path(job: job_id)

        expect(field_error).to eq("This run did not finish, and nothing was created. Upload the file again.")
        expect(page).to have_no_css("[data-work-packages--csv-import-target='poll']", visible: :all)
      end

      it "offers the form again, so the file can be sent a second time" do
        stopped(:failure)

        get show_path(job: job_id)

        expect(page).to have_button("Check file", disabled: true)
        expect(page).to have_css("[data-test-selector='import-drop-box']")
      end

      it "stops the poller that is already running" do
        stopped(:cancelled)

        get status_path(job: job_id)

        expect(response.body).not_to include("csv-import-target=\"poll\"")
        expect(response.body).to include("This run did not finish")
      end

      it "leaves a run that reported its own failure to the report" do
        create(:delayed_job_status,
          job_id:,
          user: importer,
          status: :failure,
          payload: { "project_id" => project.id, "filename" => "sprint-43.csv", "dry_run" => false,
            "outcome" => "file_rejected", "column_problems" => [], "problems" => [] })

        get show_path(job: job_id)

        expect(response.body).to include("The column headers could not be read")
        expect(response.body).not_to include("This run did not finish")
      end
    end
  end

  describe "uploading a file end to end" do
    before { login_as importer }

    def upload(dry_run: "1")
      upload_content(WorkPackages::Import::CSV::Template.call(project:), dry_run:)
    end

    def upload_content(body, dry_run: "1")
      file = Tempfile.new(["import", ".csv"])
      file.write(body)
      file.close

      post show_path, params: { file: Rack::Test::UploadedFile.new(file.path, "text/csv"), dry_run: }
    end

    it "shows the run it just started rather than an empty page" do
      upload
      follow_redirect!

      expect(response.body).to include("Checking")
      expect(page).to have_css("[data-work-packages--csv-import-target='poll']", visible: :all)
    end

    it "identifies the project from the first status write, before the job has run" do
      upload

      expect(JobStatus::Status.sole.payload).to include("project_id" => project.id)
    end

    it "reports the outcome once the job has run" do
      upload
      perform_enqueued_jobs

      get show_path(job: JobStatus::Status.sole.job_id)

      expect(response.body).to include("lines checked, no problems found")
      expect(page).to have_button("Import 2 work packages")
    end

    it "shows the run it started, and marks it for polling" do
      upload
      perform_enqueued_jobs
      attachment_id = JobStatus::Status.sole.payload["attachment_id"]

      post show_path, params: { attachment_id:, dry_run: "0" }
      follow_redirect!

      expect(response.body).to include("Importing")
      expect(page).to have_css("[data-work-packages--csv-import-target='poll']", visible: :all)
    end

    it "puts the form away once a run has produced something, offering Clear instead" do
      upload
      perform_enqueued_jobs

      get show_path(job: JobStatus::Status.sole.job_id)

      expect(page).to have_no_css("[data-test-selector='import-drop-box']")
      expect(page).to have_no_field("dry_run", type: "checkbox")
      expect(page).to have_no_button("Check file")
      expect(page).to have_link("Clear")
    end

    it "offers Clear beside the button when rows were rejected, so the report can be put away" do
      upload_content("Subject,Type\n,Task\n")
      perform_enqueued_jobs

      get show_path(job: JobStatus::Status.sole.job_id)

      expect(page).to have_text("Nothing was imported")
      expect(page).to have_button("Check file", disabled: :all)
      expect(page).to have_link("Clear")
    end

    it "offers Clear beside the button when the header was rejected" do
      upload_content("Nonsense\nvalue\n")
      perform_enqueued_jobs

      get show_path(job: JobStatus::Status.sole.job_id)

      expect(page).to have_text("The column headers could not be read")
      expect(page).to have_button("Check file", disabled: :all)
      expect(page).to have_link("Clear")
    end

    it "offers Clear beside the button where the file was refused with a banner and no table" do
      upload_content("Subject\n")
      perform_enqueued_jobs

      get show_path(job: JobStatus::Status.sole.job_id)

      expect(page).to have_text("no lines underneath them")
      expect(page).to have_button("Check file", disabled: :all)
      expect(page).to have_link("Clear")
    end

    it "imports the checked file without a second upload" do
      upload
      perform_enqueued_jobs
      attachment_id = JobStatus::Status.sole.payload["attachment_id"]

      expect { perform_enqueued_jobs { post show_path, params: { attachment_id:, dry_run: "0" } } }
        .to change(WorkPackage, :count).by(2)
    end
  end

  describe "a refused upload" do
    before { login_as importer }

    def upload(file)
      post show_path, params: { file:, dry_run: "1" }
    end

    it "asks for a file when none was chosen" do
      post show_path, params: { dry_run: "1" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(field_error).to eq("Choose a CSV file to upload.")
    end

    it "offers Clear beside the button, so the refusal can be put away" do
      post show_path, params: { dry_run: "1" }

      expect(page).to have_button("Check file", disabled: :all)
      expect(page).to have_link("Clear")
    end

    it "asks for a file when the field holds something that is not one" do
      post show_path, params: { file: "/etc/hostname" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(field_error).to eq("Choose a CSV file to upload.")
      expect(WorkPackages::Import::CSV::CsvImportJob).not_to have_been_enqueued
    end

    it "names an empty file rather than running a job for it" do
      empty = Tempfile.new(["empty", ".csv"])
      empty.close

      expect { upload(Rack::Test::UploadedFile.new(empty.path, "text/csv")) }
        .not_to change(Attachment, :count)
      expect(field_error).to eq("This file is empty.")
      expect(WorkPackages::Import::CSV::CsvImportJob).not_to have_been_enqueued
    end

    it "refuses a file that is not a CSV without storing it" do
      binary = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/image.png"), "text/csv")

      expect { upload(binary) }.not_to change(Attachment, :count)
      expect(field_error).to include(I18n.t("work_packages.import.csv.format.unknown"))
    end

    it "names both figures when the file is over the limit" do
      allow(Setting).to receive(:attachment_max_size).and_return("1")

      big = Tempfile.new(["big", ".csv"])
      big.write("Subject\n#{'a' * 4096}\n")
      big.close

      expect { upload(Rack::Test::UploadedFile.new(big.path, "text/csv")) }
        .not_to change(Attachment, :count)
      expect(field_error).to include("1 kB")
      expect(field_error).to include("4 kB")
      expect(field_error).to include("Split the lines across several files")
    end

    it "renders a storage failure as a field error rather than a 500" do
      allow(Attachments::CreateService).to receive(:bypass_allowlist).and_raise("disk on fire")

      upload(Rack::Test::UploadedFile.new(csv_fixture, "text/csv"))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(field_error).to eq("disk on fire")
    end

    it "tells the client the limit before anything is uploaded" do
      get show_path

      expect(response.body).to include("data-work-packages--csv-import-max-size-value")
      expect(response.body).to include("larger than the")
    end
  end

  describe "committing a checked file that has been swept" do
    let(:job_id) { SecureRandom.uuid }

    before do
      login_as importer
      create(:delayed_job_status,
        job_id:,
        user: importer,
        status: :success,
        payload: { "project_id" => project.id, "filename" => "sprint-43.csv",
                   "outcome" => "checked", "row_count" => 142, "created_count" => 142,
                   "attachment_id" => 0, "counts" => {}, "problems" => [],
                   "column_problems" => [], "query_id" => nil,
                   "account_count" => 0, "dated_count" => 0 })
    end

    it "keeps the summary rather than reading as though the check went wrong" do
      post show_path, params: { attachment_id: 0, dry_run: "0", job: job_id }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("142 lines checked, no problems found")
    end

    it "names the file in the message" do
      post show_path, params: { attachment_id: 0, dry_run: "0", job: job_id }

      expect(field_error).to include("sprint-43.csv")
      expect(field_error).to include("uploaded again")
    end

    it "returns the form with the dry run cleared and the button reading Import file" do
      post show_path, params: { attachment_id: 0, dry_run: "0", job: job_id }

      expect(page).to have_field("dry_run", type: "checkbox", checked: false)
      expect(page).to have_button("Import file", disabled: true)
    end
  end

  describe "the problems download" do
    let(:job_id) { SecureRandom.uuid }

    before do
      login_as importer
      create(:delayed_job_status,
        job_id:,
        user: importer,
        status: :failure,
        payload: { "project_id" => project.id,
          "filename" => "sprint-43.csv",
          "outcome" => "rows_rejected",
          "problems" => [{ "row" => 7, "attribute" => "type", "value" => "Taks",
            "message" => "does not exist in this project." }],
          "available" => { "type" => %w[Task Bug Milestone] } })
    end

    it "sends the problems as a CSV named after the file they came from" do
      get import_problems_project_work_packages_path(project, job: job_id)

      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Disposition"]).to include("sprint-43-problems.csv")
      expect(CSV.parse(response.body.delete_prefix("﻿")))
        .to eq([%w[Line Column Value Problem Available],
          ["7", "Type", "Taks", "does not exist in this project.", "Task, Bug, Milestone"]])
    end

    it "gives nothing for a job belonging to somebody else" do
      login_as create(:admin)

      get import_problems_project_work_packages_path(project, job: job_id)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "the template" do
    before { login_as importer }

    it "sends what the template builder produced, named for download" do
      get template_path

      expect(response.body).to eq(WorkPackages::Import::CSV::Template.call(project:))
      expect(response.headers["Content-Disposition"])
        .to include(WorkPackages::Import::CSV::Template::FILENAME)
    end
  end
end
