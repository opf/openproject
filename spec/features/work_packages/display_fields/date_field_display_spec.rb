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

RSpec.describe "Show the date of a Work Package", :js do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:work_package) do
    create(:work_package,
           project:,
           due_date: Date.yesterday,
           type:,
           status: open_status)
  end

  let(:open_status) { create(:default_status) }
  let(:closed_status) { create(:closed_status) }

  let(:wp_page) { Pages::FullWorkPackage.new(work_package, project) }

  let(:type) { create(:type) }
  let!(:workflow) do
    create(:workflow,
           type_id: type.id,
           old_status: open_status,
           new_status: closed_status)
  end

  context "with an overdue date" do
    before do
      login_as(admin)
      wp_page.visit!
    end

    it "is highlighted only if the WP status is open (#33457)" do
      # Highlighted with an open status
      expect(page).to have_css(".inline-edit--display-field.combinedDate .__hl_date_overdue")

      # Change status to closed
      status_field = WorkPackageStatusField.new(page)
      status_field.update(closed_status.name)

      # Not highlighted with a closed status
      expect(page).to have_no_css(".inline-edit--display-field.combinedDate .__hl_date_overdue")
    end
  end
end
