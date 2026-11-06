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

RSpec.describe "Backlogs card menu", type: :rails_request do
  shared_let(:type) { create(:type) }
  shared_let(:project) do
    create(:project, types: [type], enabled_module_names: %i[backlogs work_package_tracking])
  end
  shared_let(:sprint_a) { create(:sprint, project:, name: "Sprint A") }
  shared_let(:sprint_b) { create(:sprint, project:, name: "Sprint B") }

  let(:permissions) { %i[view_work_packages edit_work_packages view_sprints manage_sprint_items] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  current_user { user }

  def get_menu(ids:, invoker_id: ids.first)
    get menu_project_backlogs_work_packages_path(project, ids:, invoker_id:)
  end

  def menu
    Capybara.string(response.body)
  end

  def menu_item_id(work_package, item)
    "work_package_#{work_package.id}_menu_#{item}"
  end

  context "with the invoker alone" do
    let!(:invoker) { create(:work_package, sprint: sprint_a, type:, project:) }

    it "renders the invoker's singular menu for ids: [invoker]", :aggregate_failures do
      get_menu(ids: [invoker.id])

      expect(response).to have_http_status(:ok)
      expect(menu).to have_element(:ul, id: "work_package_#{invoker.id}_menu-list")
      expect(menu).to have_element(:a, id: menu_item_id(invoker, :open_details))
      expect(menu).to have_element(:"clipboard-copy", id: menu_item_id(invoker, :copy_work_package_id))
      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_sprint))
      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_inbox))
    end
  end

  describe "offers a sprint only when every member permits it", with_ee: %i[readonly_work_packages] do
    shared_let(:readonly_status) { create(:status, :readonly) }

    let!(:confined) { create(:work_package, sprint: sprint_a, status: readonly_status, type:, project:) }

    context "when a confined member sits in one sprint and a free member elsewhere" do
      let!(:free) { create(:work_package, type:, project:) }

      it "offers the sprint every member can reach" do
        get_menu(ids: [free.id, confined.id])

        expect(menu).to have_element(:button, id: menu_item_id(free, :move_to_sprint))
      end
    end

    context "when the only other sprint is refused by a confined member" do
      let!(:free) { create(:work_package, sprint: sprint_a, type:, project:) }

      it "offers no sprint", :aggregate_failures do
        get_menu(ids: [free.id, confined.id])

        expect(response).to have_http_status(:ok)
        expect(menu).to have_no_element(:button, id: menu_item_id(free, :move_to_sprint))
      end
    end
  end

  context "when every member is already in the inbox" do
    let!(:first) { create(:work_package, type:, project:) }
    let!(:second) { create(:work_package, type:, project:) }

    it "omits a target every member is already in" do
      get_menu(ids: [first.id, second.id])

      expect(menu).to have_no_element(:button, id: menu_item_id(first, :move_to_inbox))
    end
  end

  context "when one member is in the inbox and another is not" do
    let!(:invoker) { create(:work_package, type:, project:) }
    let!(:sprinted) { create(:work_package, sprint: sprint_a, type:, project:) }

    it "offers the inbox" do
      get_menu(ids: [invoker.id, sprinted.id])

      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_inbox))
    end
  end

  context "when a member is gone" do
    let!(:invoker) { create(:work_package, sprint: sprint_a, type:, project:) }
    let!(:gone) { create(:work_package, type:, project:) }

    before { gone.destroy }

    it "falls back to the invoker when a member is gone", :aggregate_failures do
      get_menu(ids: [invoker.id, gone.id], invoker_id: invoker.id)

      expect(response).to have_http_status(:ok)
      expect(menu).to have_element(:a, id: menu_item_id(invoker, :open_details))
      expect(menu).to have_element(:button, id: menu_item_id(invoker, :move_to_inbox))
    end
  end

  context "when the invoker is gone" do
    let!(:member) { create(:work_package, type:, project:) }
    let!(:invoker) { create(:work_package, type:, project:) }

    before { invoker.destroy }

    it "responds with not found" do
      get_menu(ids: [member.id, invoker.id], invoker_id: invoker.id)

      expect(response).to have_http_status(:not_found)
    end
  end

  context "with more ids than the batch cap" do
    let!(:work_packages) do
      create_list(:work_package, Backlogs::WorkPackages::BatchUpdateService::MAX_BATCH_SIZE + 1, type:, project:)
    end

    it "renders the menu for more than 50 ids" do
      get_menu(ids: work_packages.map(&:id))

      expect(response).to have_http_status(:ok)
    end
  end

  context "without the view_sprints permission" do
    let(:permissions) { %i[view_work_packages] }
    let!(:invoker) { create(:work_package, type:, project:) }

    it "refuses without view permission" do
      get_menu(ids: [invoker.id])

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "parameter validation" do
    let!(:invoker) { create(:work_package, type:, project:) }
    let!(:other) { create(:work_package, type:, project:) }

    it "rejects an invoker outside ids" do
      get_menu(ids: [other.id], invoker_id: invoker.id)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects duplicate ids" do
      get_menu(ids: [invoker.id, invoker.id])

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a blank id" do
      get_menu(ids: [invoker.id, ""])

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
