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

RSpec.describe "Projects#destroy", :js, :with_cuprite do
  let!(:project) { create(:project, name: "foo", identifier: "foo") }
  let(:project_page) { Pages::Projects::Destroy.new(project) }
  let(:danger_zone) { DangerZone.new(page) }

  current_user { create(:admin) }

  before { project_page.visit! }

  it "destroys the project" do
    # Confirm the deletion
    # Without confirmation, the button is disabled
    expect(danger_zone).to be_disabled

    # With wrong confirmation, the button is disabled
    danger_zone.confirm_with("#{project.identifier}_wrong")

    expect(danger_zone).to be_disabled

    # With correct confirmation, the button is enabled
    # and the project can be deleted
    danger_zone.confirm_with(project.identifier)
    expect(danger_zone).not_to be_disabled
    danger_zone.danger_button.click

    expect(page).to have_css ".op-toast.-success", text: I18n.t("projects.delete.scheduled")
    expect(project.reload).to eq(project)

    perform_enqueued_jobs

    expect { project.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
