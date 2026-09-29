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

require "spec_helper"

RSpec.describe "Enabling a work package type in all projects", :skip_csrf,
               type: :rails_request, with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:one) { create(:project, name: "Foundry") }
  shared_let(:other) { create(:project, name: "Laboratory") }

  let(:variant) { type.default_variant }

  before { login_as admin }

  def toggle(value)
    post enable_all_type_projects_path(type_id: type.id, value:), as: :turbo_stream
  end

  it "enables the type everywhere and offers to disable it next" do
    toggle("1")

    expect(response).to have_http_status(:ok)
    expect(variant.projects).to contain_exactly(one, other)
    expect(response.body).to include(I18n.t("types.edit.projects.disable_all"))
    expect(response.body).not_to include(I18n.t("types.edit.projects.enable_all"))
  end

  it "disables it everywhere and offers to enable it next" do
    create(:project_type, project: one, type:)
    create(:project_type, project: other, type:)

    toggle("0")

    expect(variant.reload.projects).to be_empty
    expect(response.body).to include(I18n.t("types.edit.projects.enable_all"))
  end

  context "when one project refuses" do
    shared_let(:blocked) { create(:project, name: "Blocked") }

    before do
      [one, other, blocked].each { |project| create(:project_type, project:, type:) }
      create(:work_package, project: blocked, type:)
    end

    it "still repaints the list and the button" do
      toggle("0")

      expect(response).to have_http_status(:unprocessable_entity)
      expect(variant.reload.projects).to contain_exactly(blocked)
      expect(response.body).to include("projects-table")
      expect(response.body).to include(I18n.t("types.edit.projects.enable_all"))
    end

    it "reports which project stood in the way" do
      toggle("0")

      expect(response.body).to include("Blocked")
    end
  end

  describe "the toggle label after the project set changes some other way" do
    def add(project)
      post link_type_projects_path(type_id: type.id),
           params: { project_ids: [{ nodeId: project.id.to_s }.to_json] },
           as: :turbo_stream
    end

    def remove(project)
      delete unlink_type_projects_path(type_id: type.id, project_id: project.id), as: :turbo_stream
    end

    it "offers to disable once the last remaining project has been added" do
      create(:project_type, project: one, type:)

      add(other)

      expect(variant.reload.projects).to contain_exactly(one, other)
      expect(response.body).to include(I18n.t("types.edit.projects.disable_all"))
      expect(response.body).not_to include(I18n.t("types.edit.projects.enable_all"))
    end

    it "offers to enable again once one project has been removed from the full set" do
      [one, other].each { |project| create(:project_type, project:, type:) }

      remove(other)

      expect(variant.reload.projects).to contain_exactly(one)
      expect(response.body).to include(I18n.t("types.edit.projects.enable_all"))
      expect(response.body).not_to include(I18n.t("types.edit.projects.disable_all"))
    end
  end
end
