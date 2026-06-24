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

require "rails_helper"

RSpec.describe ResourcePlannerViews::UserCardList::CardComponent, type: :component do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:current_user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end
  shared_let(:card_user) do
    create(:user, firstname: "Carl", lastname: "Cardman",
                  member_with_permissions: { project => %i[view_resource_planners] })
  end

  let(:details_path) { "/projects/x/users/#{card_user.id}/resource_allocations" }
  let(:remove_path) { nil }
  let(:utilization) { nil }

  subject(:rendered) do
    render_inline(described_class.new(user: card_user, details_path:, remove_path:, utilization:))
    page
  end

  before { login_as(current_user) }

  it "wires the whole card to open the details path" do
    expect(rendered).to have_css(
      "[data-test-selector='op-user-card']" \
      "[data-resource-management--user-card-url-value='#{details_path}']"
    )
  end

  context "for a user the current user cannot see" do
    let(:hidden_user) { create(:user, firstname: "Hidden", lastname: "User") }

    it "renders nothing" do
      render_inline(described_class.new(user: hidden_user, details_path: "/x"))

      expect(page).to have_no_text("Hidden User")
    end
  end

  describe "the email" do
    it "is hidden for another user without the view-user-email permission" do
      expect(rendered).to have_no_text(card_user.mail)
    end

    context "when the current user may view emails" do
      shared_let(:current_user) do
        create(:user,
               global_permissions: %i[view_user_email],
               member_with_permissions: { project => %i[view_resource_planners] })
      end

      it "is shown" do
        expect(rendered).to have_text(card_user.mail)
      end
    end
  end

  describe "the utilization section" do
    context "with a utilization value" do
      let(:utilization) { 75 }

      it "renders the utilization label and percentage" do
        expect(rendered).to have_text(I18n.t("resource_management.user_card_list.utilization.label"))
        expect(rendered).to have_text("75%")
      end
    end

    context "without a utilization value" do
      it "omits the utilization section" do
        expect(rendered).to have_no_text(I18n.t("resource_management.user_card_list.utilization.label"))
      end
    end
  end

  describe "the remove button" do
    context "in manual mode" do
      let(:remove_path) { "/projects/x/views/1/users/#{card_user.id}" }

      it "renders a delete action" do
        expect(rendered).to have_css("a[href='#{remove_path}'][data-turbo-method='delete']")
      end
    end

    context "in automatic mode" do
      it "renders no delete action" do
        expect(rendered).to have_no_css("a[data-turbo-method='delete']")
      end
    end
  end
end
