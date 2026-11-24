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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Forms and workflows started in the creation wizard", :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }

  before { login_as admin }

  let(:variant) { type.default_variant }

  def page = Capybara.string(response.body)

  describe "carrying the started workflow" do
    before { get type_creation_wizard_path(type_id: type.id, step: :workflows, started_workflow_id: 42) }

    it "keeps it on the address the step submits to" do
      expect(page).to have_css("form#type-wizard-form[action*='started_workflow_id=42']")
    end

    it "keeps it on the address the change dialog returns to" do
      expect(page).to have_css("[data-test-selector='workflow-choice-existing'][data-dialog-url*='started_workflow_id%3D42']",
                               visible: :all)
    end
  end
end
