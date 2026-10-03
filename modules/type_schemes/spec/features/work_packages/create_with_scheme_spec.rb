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
require "rack/test"

RSpec.describe "Creating work packages with a type scheme", :js do
  include API::V3::Utilities::PathHelper

  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:story) { create(:type, name: "Story") }
  shared_let(:task) { create(:type, name: "Task") }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:project) { create(:project, types: [epic, story, task, bug]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages edit_work_packages] })
  end
  shared_let(:existing_bug) { create(:work_package, project:, type: bug, subject: "Old bug") }

  let(:scheme) { create(:type_scheme, name: "Dev", types: [story, epic, task]) }
  let(:wp_page) { Pages::FullWorkPackageCreate.new(project:) }

  before do
    TypeSchemes::SchemeService.assign(project, scheme)
    login_as(user)
  end

  it "offers only scheme types with the scheme default preselected" do
    wp_page.visit!
    wp_page.expect_fully_loaded

    type_select = find(".inline-edit--container.type select")
    expect(type_select.all("option").map(&:text)).to eq %w[Story Epic Task]
    expect(type_select.value).to eq story.id.to_s
  end

  it "keeps an existing work package of an outside type editable" do
    visit project_work_package_path(project, existing_bug.id, "activity")
    expect(page).to have_text("Old bug")
    expect(existing_bug.reload.type).to eq bug
  end

  context "when a type is removed from the scheme" do
    let!(:existing_task) { create(:work_package, project:, type: task, subject: "Old task") }

    it "does not change existing work packages" do
      TypeSchemes::SchemeService.update(scheme, items: [{ type_id: story.id, position: 1, is_default: true },
                                                         { type_id: epic.id, position: 2, is_default: false }])

      expect(existing_task.reload.type).to eq task
      expect(TypeSchemes::Resolver.allowed_types(project).map(&:id)).to eq [story.id, epic.id]
    end
  end
end

RSpec.describe "API creating work packages with a type scheme" do # rubocop:disable RSpec/DescribeClass
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:story) { create(:type, name: "Story") }
  shared_let(:bug) { create(:type, name: "Bug") }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:project) { create(:project, types: [story, bug]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages add_work_packages] })
  end

  before do
    TypeSchemes::SchemeService.assign(project, create(:type_scheme, types: [story]))
    login_as(user)
  end

  def create_with(type)
    payload = { subject: "New",
                _links: { type: { href: api_v3_paths.type(type.id) },
                          project: { href: api_v3_paths.project(project.id) } } }
    post api_v3_paths.work_packages, payload.to_json, "CONTENT_TYPE" => "application/json"
  end

  it "rejects a type outside the scheme with 422" do
    create_with(bug)
    expect(last_response).to have_http_status(:unprocessable_entity)
  end

  it "accepts a type inside the scheme" do
    create_with(story)
    expect(last_response).to have_http_status(:created)
  end
end
