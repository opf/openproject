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

require "rails_helper"

RSpec.describe PlaceholderUsers::TableComponent, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    # `sortable?` makes the component sort via SortHelper, which needs an
    # action name to key the session's sort criteria by.
    vc_test_controller.instance_variable_set(:@_action_name, "index")

    with_request_url("/placeholder_users") do
      render_inline(described_class.new(...))
    end
  end

  subject(:rendered_component) do
    render_component(rows: placeholder_users)
  end

  shared_examples_for "rendering Border Box Grid headings" do
    include_examples "rendering Border Box Grid heading", text: "Name"
    include_examples "rendering Border Box Grid heading", text: "Criteria"
    include_examples "rendering Border Box Grid heading", text: "Created on"
    include_examples "rendering Border Box Grid mobile heading", text: "Placeholder users"
  end

  context "with no placeholder users" do
    let(:placeholder_users) { PlaceholderUser.none }

    it_behaves_like "rendering Box", row_count: 1
    it_behaves_like "rendering Border Box Grid headings"
    it_behaves_like "rendering Blank Slate", heading: "No placeholder users"
  end

  context "with placeholder users" do
    let(:marketing_user) { create(:placeholder_user, name: "Marketing") }
    let(:sales_user) { create(:placeholder_user, name: "Sales") }
    let(:placeholder_users) { PlaceholderUser.where(id: [marketing_user.id, sales_user.id]) }

    before { User.current = current_user }

    context "as an admin" do
      let(:current_user) { create(:admin) }

      it_behaves_like "rendering Box", row_count: 2
      it_behaves_like "rendering Border Box Grid headings"
      it_behaves_like "rendering Border Box Grid rows", row_count: 2, col_count: 3

      it "renders a link to edit each placeholder user" do
        expect(rendered_component).to have_link(marketing_user.name, href: edit_placeholder_user_path(marketing_user))
        expect(rendered_component).to have_link(sales_user.name, href: edit_placeholder_user_path(sales_user))
      end

      it "renders a delete button for each placeholder user" do
        expect(rendered_component).to have_link(
          accessible_name: I18n.t("placeholder_users.delete_tooltip"),
          href: deletion_info_placeholder_user_path(marketing_user)
        )
        expect(rendered_component).to have_link(
          accessible_name: I18n.t("placeholder_users.delete_tooltip"),
          href: deletion_info_placeholder_user_path(sales_user)
        )
      end
    end

    context "as a user without the right to manage members" do
      let(:current_user) { create(:user) }

      it "renders no delete button, only a disabled hint" do
        expect(rendered_component).to have_no_link(accessible_name: I18n.t("placeholder_users.delete_tooltip"))
        expect(rendered_component).to have_css(".icon-help2", count: 2)
      end
    end
  end
end
