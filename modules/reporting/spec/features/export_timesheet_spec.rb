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

require_relative "../spec_helper"
require_relative "support/pages/cost_report_page"

RSpec.describe "Timesheet PDF export", :js do
  include PDFExportSpecUtils

  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:admin) }
  shared_let(:cost_type) { create(:cost_type, name: "Post-war", unit: "cap", unit_plural: "caps") }
  shared_let(:work_package) { create(:work_package, project:, subject: "Some task") }
  shared_let(:cost_entry) { create(:cost_entry, user:, entity: work_package, project:, cost_type:) }
  let(:report_page) { Pages::CostReportPage.new project }

  current_user { user }

  it "can download the PDF" do
    report_page.visit!

    # The export opens a new tab with the result
    new_window = window_opened_by do
      click_on I18n.t("export.timesheet.button")

      expect(page).to have_content I18n.t("job_status_dialog.generic_messages.in_queue")

      perform_enqueued_jobs

      expect(page).to have_text(I18n.t("export.succeeded"))
    end

    # Switching to that tab and checking that the content is a PDF
    within_window new_window do
      expect_current_url_to_be_pdf
    end
  end
end
