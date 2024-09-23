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

RSpec.describe "project export", :js, :with_cuprite do
  shared_let(:important_project) { create(:project, name: "Important schedule plan", description: "Important description") }
  shared_let(:party_project) { create(:project, name: "Christmas party", description: "Christmas description") }
  shared_let(:user) do
    create(:user, member_with_permissions: {
             important_project => %i[view_project edit_project view_work_packages],
             party_project => %i[view_project edit_project view_work_packages]
           })
  end

  let(:index_page) { Pages::Projects::Index.new }

  let(:current_user) { user }

  before do
    @download_list = DownloadList.new

    login_as(current_user)

    index_page.visit!
  end

  after do
    DownloadList.clear
  end

  subject { @download_list.refresh_from(page).latest_downloaded_content } # rubocop:disable RSpec/InstanceVariable

  def export!(expect_success: true)
    index_page.click_more_menu_item "Export"
    click_on export_type

    # Expect to get a response regarding queuing
    expect(page).to have_content I18n.t("job_status_dialog.generic_messages.in_queue"),
                                 wait: 10

    begin
      perform_enqueued_jobs
    rescue StandardError
      # nothing
    end

    if expect_success
      expect(page).to have_text(I18n.t("export.succeeded"))
    end
  end

  describe "CSV export" do
    let(:export_type) { "CSV" }

    it "exports the visible projects" do
      index_page.expect_projects_listed(important_project)

      export!

      expect(subject).to have_text(important_project.name)
    end

    context "with a filter set to match only one project" do
      it "exports with that filter" do
        index_page.expect_projects_listed(important_project, party_project)

        index_page.open_filters

        index_page.set_filter("name_and_identifier",
                              "Name or identifier",
                              "contains",
                              ["Important"])
        wait_for_reload

        index_page.set_columns("Name", "Description")

        index_page.expect_projects_listed(important_project)
        index_page.expect_projects_not_listed(party_project)

        export!

        expect(subject).to have_text(important_project.name)
        expect(subject).to have_text(important_project.description)
        expect(subject).to have_no_text(party_project.name)
        expect(subject).to have_no_text(party_project.description)
      end
    end

    context "with a persisted list" do
      let(:my_projects_list) do
        create(:project_query, name: "My projects list", user:) do |query|
          query.where("name_and_identifier", "~", ["Important"])
          query.select("name", "description")

          query.save!
        end
      end

      before do
        my_projects_list
      end

      it "exports with the filters persisted in the list" do
        index_page.visit!

        index_page.set_sidebar_filter(my_projects_list.name)

        index_page.expect_projects_listed(important_project)
        index_page.expect_projects_not_listed(party_project)

        export!

        expect(subject).to have_text(important_project.name)
        expect(subject).to have_text(important_project.description)
        expect(subject).to have_no_text(party_project.name)
        expect(subject).to have_no_text(party_project.description)
      end
    end
  end
end
