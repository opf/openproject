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

RSpec.describe Grids::Widgets::Members, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }

  current_user { user }

  subject(:rendered_component) do
    render_component(project)
  end

  shared_examples "empty-state without action" do
    it "renders blankslate without action button" do
      expect(rendered_component).to have_test_selector(empty_selector)
      expect(rendered_component).to have_text(empty_message)
      expect(rendered_component).to have_no_test_selector("members-widget-add-button")
    end
  end

  shared_examples "empty-state with action" do
    it "renders blankslate with action button" do
      expect(rendered_component).to have_test_selector("members-widget-empty")
      expect(rendered_component).to have_text("This widget is currently empty.")
      expect(rendered_component).to have_test_selector("members-widget-add-button")
    end
  end

  context "when user cannot view members" do
    let(:empty_selector) { "members-widget-no-permission" }
    let(:empty_message)  { "This widget is not available." }

    it_behaves_like "empty-state without action"
  end

  context "with no members" do
    let(:empty_selector) { "members-widget-empty" }
    let(:empty_message)  { "This widget is currently empty." }

    context "when user can view but cannot manage members" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_members, project:)
        end
      end

      it_behaves_like "empty-state without action"
    end

    context "when user can view and manage members" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_members, :manage_members, project:)
        end
      end

      it_behaves_like "empty-state with action"
    end
  end

  context "with members" do
    let(:project) { create(:project) }
    let(:user) { create(:admin) }

    let!(:member) do
      create(:user, member_with_permissions: { project => [:view_members] })
    end

    before do
      member
    end

    it "renders turbo-frame wrapper" do
      expect(rendered_component).to have_element :"turbo-frame"
    end

    it "renders members items", :aggregate_failures do
      expect(rendered_component).to have_element class: "op-widget-box--body" do |body|
        expect(body).to have_element :"opce-principal"
      end
    end

    it "renders link to view all members" do
      expect(rendered_component).to have_test_selector("members-widget-footer") do |footer|
        expect(footer).to have_link href: project_members_path(project)
      end
    end
  end
end
