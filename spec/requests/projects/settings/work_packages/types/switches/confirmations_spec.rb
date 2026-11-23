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

RSpec.describe "Confirming a project's variant switch",
               :skip_csrf,
               type: :rails_request do
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:delivery) { create(:type_variant, type: epic, variant_name: "Delivery") }
  shared_let(:project) { create(:project, name: "Harbor", types: [epic]) }
  shared_let(:theirs) do
    create(:project_owned_type_variant, type: epic, project: create(:project), variant_name: "Demo only")
  end

  let(:user) { create(:user, member_with_permissions: { project => %i[view_project manage_project_variants] }) }
  let(:target) { delivery }

  before { login_as user }

  subject do
    get new_project_settings_work_packages_type_switch_confirmation_path(project, epic),
        params: { target_id: target.id },
        as: :turbo_stream
  end

  it "asks to confirm, naming the variant it switches to" do
    subject

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Switch type variant?").and include("Switching to Epic: Delivery")
  end

  it "switches through the project's own switch" do
    subject

    expect(response.body).to include(%(action="#{project_settings_work_packages_type_switch_path(project, epic)}"))
  end

  context "with the variant the project already uses" do
    let(:target) { epic.default_variant }

    it "refuses inside the dialog, without asking to confirm" do
      subject

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("The project already uses this type or variant.")
      expect(response.body).not_to include("Switch type variant?")
    end
  end

  context "with a variant another project owns" do
    let(:target) { theirs }

    it "refuses it" do
      subject

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).not_to include("Switch type variant?")
    end
  end

  context "when the member may only choose which types the project uses" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_project manage_types] }) }

    it "is refused" do
      subject

      expect(response).to have_http_status(:forbidden)
    end
  end
end
