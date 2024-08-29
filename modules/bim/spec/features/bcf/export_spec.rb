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
require_relative "../../support/pages/ifc_models/show_default"

RSpec.describe "bcf export", :js,
               with_config: { edition: "bim" } do
  let(:status) { create(:status, name: "New", is_default: true) }
  let(:closed_status) { create(:closed_status, name: "Closed") }
  let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking]) }

  let!(:open_work_package) { create(:work_package, project:, subject: "Open WP", status:) }
  let!(:closed_work_package) { create(:work_package, project:, subject: "Closed WP", status: closed_status) }
  let!(:open_bcf_issue) { create(:bcf_issue, work_package: open_work_package) }
  let!(:closed_bcf_issue) { create(:bcf_issue, work_package: closed_work_package) }

  let(:permissions) do
    %i[view_ifc_models
       view_linked_issues
       manage_bcf
       add_work_packages
       edit_work_packages
       view_work_packages
       export_work_packages]
  end

  let(:current_user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end

  let!(:model) do
    create(:ifc_model_minimal_converted,
           project:,
           uploader: current_user)
  end

  let(:model_page) { Pages::IfcModels::ShowDefault.new project }
  let(:wp_cards) { Pages::WorkPackageCards.new(project) }
  let(:filters) { Components::WorkPackages::Filters.new }

  before do
    login_as current_user
    @download_list = DownloadList.new
  end

  after do
    DownloadList.clear
  end

  def export_into_bcf_extractor
    DownloadList.clear
    page.find(".export-bcf-button").click

    # Expect to get a response regarding queuing
    expect(page).to have_content(I18n.t("job_status_dialog.generic_messages.in_queue"),
                                 wait: 10)

    perform_enqueued_jobs
    expect(page).to have_text(I18n.t("export.succeeded"))

    # Close the modal
    page.find(".Overlay-closeButton").click

    @download_list.refresh_from(page)

    # Check the downloaded file
    OpenProject::Bim::BcfXml::Importer.new(
      @download_list.latest_download,
      project,
      current_user:
    ).extractor_list
  end

  it "can export the open and closed BCF issues (Regression #30953)" do
    model_page.visit!
    wp_cards.expect_work_package_listed(open_work_package)
    wp_cards.expect_work_package_not_listed(closed_work_package)
    filters.expect_filter_count(1)

    # Expect only the open issue
    extractor_list = export_into_bcf_extractor
    expect(extractor_list.length).to eq(1)
    expect(extractor_list.first[:title]).to eq("Open WP")

    model_page.visit!
    # Change the query to show all statuses
    filters.open
    filters.remove_filter("status")
    filters.expect_filter_count(0)

    wp_cards.expect_work_package_listed(open_work_package, closed_work_package)

    # Download again
    extractor_list = export_into_bcf_extractor
    expect(extractor_list.length).to eq(2)

    titles = extractor_list.pluck(:title)
    expect(titles).to contain_exactly("Open WP", "Closed WP")
  end
end
