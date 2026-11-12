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

RSpec.describe AttributeHelpTexts::ShowDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:attribute_help_text) { build_stubbed(:project_help_text, help_text:) }
  let(:help_text) do
    <<~MARKDOWN
      ## The lowdown on filling in this form field!
      ### Getting started

      Take a deep breath! _It ain't hard!_ Relax and have your Kaffee und Kuchen. Or a cup of tea if you're British.
    MARKDOWN
  end

  let(:current_user) { build_stubbed(:user) }

  subject do
    render_inline(described_class.new(attribute_help_text:, current_user:))
    page
  end

  it "renders a dialog" do
    expect(subject).to have_element :dialog
  end

  it "applies an ID" do
    expect(subject).to have_element id: "dialog_attribute_help_text_project_#{attribute_help_text.id}"
  end

  describe "dialog heading" do
    it "renders the heading" do
      expect(subject).to have_heading attribute_help_text.attribute_field_name
    end
  end

  describe "dialog body" do
    it "applies correct classes to user-generated content" do
      expect(subject).to have_css ".op-uc-container.op-uc-container__no-permalinks"
    end

    it "renders the user-generated content", :aggregate_failures do
      expect(subject).to have_css "h2", text: "The lowdown on filling in this form field!"
      expect(subject).to have_css "h3", text: "Getting started"
      expect(subject).to have_text "Relax and have your Kaffee und Kuchen"
    end

    context "without attachments" do
      it "does not render the Attachments heading" do
        expect(subject).to have_no_heading "Attachments"
      end

      it "does not render the opce-attachments component" do
        expect(subject).to have_no_element "opce-attachments"
      end
    end

    context "with attachments" do
      let!(:attachments) { create_list(:attachment, 2, container: attribute_help_text) }

      it "renders the Attachments heading" do
        expect(subject).to have_heading "Attachments"
      end

      it "renders the opce-attachments component" do
        expect(subject).to have_element "opce-attachments" do |element|
          expect(element["data-allow-uploading"]).to be_json_eql("false")
          expect(element["data-destroy-immediately"]).to be_json_eql("true")
          expect(element["data-resource"]).to have_json_path("_links/attachments/href")
        end
      end
    end
  end

  describe "dialog footer" do
    it "renders a Close button" do
      expect(subject).to have_button "Close"
    end

    context "when the user does not have edit permissions" do
      it "does not render an Edit button" do
        expect(subject).to have_no_link "Edit"
      end
    end

    context "when the user has edit permissions" do
      let(:current_user) { build_stubbed(:admin) }

      it "renders an Edit button with icon" do
        expect(subject).to have_link "Edit", href: edit_attribute_help_text_path(attribute_help_text)
        expect(subject).to have_octicon :pencil
      end
    end
  end
end
