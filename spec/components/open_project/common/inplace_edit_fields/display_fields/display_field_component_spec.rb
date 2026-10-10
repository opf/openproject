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

RSpec.describe OpenProject::Common::InplaceEditFields::DisplayFields::DisplayFieldComponent,
               type: :component do
  include ViewComponent::TestHelpers

  let(:project) { build_stubbed(:project, name: "My project") }

  describe "value rendering" do
    it "renders the attribute value" do
      render_inline(described_class.new(model: project, attribute: :name, writable: false, truncated: false))

      expect(rendered_content).to have_text("My project")
    end

    it "renders a placeholder when the value is blank" do
      project = build_stubbed(:project, name: nil)
      render_inline(described_class.new(model: project, attribute: :name, writable: false, truncated: false))

      expect(rendered_content).to have_text(I18n.t("placeholders.default"))
    end

    it "renders 'Yes' for a true boolean value" do
      project = build_stubbed(:project, public: true)
      render_inline(described_class.new(model: project, attribute: :public, writable: false, truncated: false))

      expect(rendered_content).to have_text(I18n.t("general_text_Yes"))
    end

    it "renders 'No' for a false boolean value" do
      project = build_stubbed(:project, public: false)
      render_inline(described_class.new(model: project, attribute: :public, writable: false, truncated: false))

      expect(rendered_content).to have_text(I18n.t("general_text_No"))
    end
  end

  describe "editability" do
    it "marks the display field as editable when writable" do
      render_inline(described_class.new(model: project, attribute: :name, writable: true, truncated: false))

      expect(rendered_content).to have_css(".op-inplace-edit--display-field_clickable")
      expect(rendered_content).to include("click-&gt;inplace-edit#request")
    end

    it "does not mark the display field as editable when not writable" do
      render_inline(described_class.new(model: project, attribute: :name, writable: false, truncated: false))

      expect(rendered_content).to have_no_css(".op-inplace-edit--display-field_clickable")
      expect(rendered_content).not_to include("click-&gt;inplace-edit#request")
    end
  end

  describe "activation event" do
    let(:user) { build_stubbed(:user, preferences: { require_double_click_for_inline_edit: }) }

    current_user { user }

    context "when the user does not require a double click" do
      let(:require_double_click_for_inline_edit) { false }

      it "activates inline editing on click" do
        render_inline(described_class.new(model: project, attribute: :name, writable: true, truncated: false))

        expect(rendered_content).to include("\"click-&gt;inplace-edit#request")
      end

      it "opens the dialog on click" do
        render_inline(described_class.new(model: project, attribute: :name, writable: true, truncated: false,
                                          dialog_controller_name: "dialog", dialog_url: "/dialog"))

        expect(rendered_content).to include("\"click-&gt;inplace-edit#openDialog")
      end
    end

    context "when the user requires a double click" do
      let(:require_double_click_for_inline_edit) { true }

      it "activates inline editing on double click only" do
        render_inline(described_class.new(model: project, attribute: :name, writable: true, truncated: false))

        expect(rendered_content).to include("dblclick-&gt;inplace-edit#request")
        expect(rendered_content).not_to include("\"click-&gt;inplace-edit#request")
      end

      it "opens the dialog on double click only" do
        render_inline(described_class.new(model: project, attribute: :name, writable: true, truncated: false,
                                          dialog_controller_name: "dialog", dialog_url: "/dialog"))

        expect(rendered_content).to include("dblclick-&gt;inplace-edit#openDialog")
        expect(rendered_content).not_to include("\"click-&gt;inplace-edit#openDialog")
      end
    end
  end
end
