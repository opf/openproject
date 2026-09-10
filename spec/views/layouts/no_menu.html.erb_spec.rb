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

RSpec.describe "layouts/no_menu" do
  shared_let(:user) { create(:admin) }
  shared_let(:project) { create(:project) }

  helper Redmine::MenuManager::MenuHelper

  before do
    without_partial_double_verification do
      allow(controller).to receive(:default_search_scope)
      allow(view).to receive(:render_to_string)
      allow(view).to receive_messages(current_menu_item: nil, current_user: user)
    end

    allow(User).to receive(:current).and_return user
  end

  context "with a project in scope" do
    before do
      assign(:project, project)
      render
    end

    # The layout's name is its whole contract: a project in scope must not bring
    # back the project menu through render_main_menu's unnamed-menu fallback.
    it "renders no side menu" do
      expect(rendered).to have_no_css("#main-menu")
    end
  end

  context "without a project" do
    before do
      render
    end

    it "renders no side menu" do
      expect(rendered).to have_no_css("#main-menu")
    end
  end

  context "when the caller names a menu" do
    before do
      assign(:project, project)
      render template: "layouts/no_menu", locals: { menu_name: :project_menu }
    end

    it "still renders that menu" do
      expect(rendered).to have_css("#main-menu")
    end
  end
end
