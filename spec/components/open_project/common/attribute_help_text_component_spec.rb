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

RSpec.describe OpenProject::Common::AttributeHelpTextComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:block) { nil }

  subject do
    render_inline(described_class.new(help_text:), &block)
    page
  end

  shared_examples "component renders" do
    it "renders a link" do
      expect(subject).to have_link href: show_dialog_attribute_help_text_path(help_text),
                                   class: "Link"
    end

    it "renders a tooltip" do
      expect(subject).to have_element "tool-tip", text: "Show help text",
                                                  for: /attribute-help-text-component-\d+/,
                                                  popover: "manual",
                                                  "data-direction": "sw",
                                                  "data-type": "label"
    end

    it "renders an icon" do
      expect(subject).to have_octicon :question, size: :xsmall
    end

    it "connects an 'async-dialog' controller" do
      expect(subject).to have_element :a, "data-controller": "async-dialog"
    end

    it "applies .op-attribute-help-text class" do
      expect(subject).to have_element :a, class: "op-attribute-help-text"
    end

    it "applies an ID" do
      expect(subject).to have_element :a, id: /attribute-help-text-component-\d+/
    end

    it "defines a data-qa-help-text-for attribute" do
      expect(subject).to have_element :a, "data-qa-help-text-for": attribute_name.to_s.camelize(:lower)
    end

    context "without an additional label" do
      it "does not render additional label content" do
        expect(subject).to have_no_css ".Link-content"
      end
    end

    context "with an additional label" do
      let(:block) do
        proc do |help_text|
          help_text.with_additional_label_content "Normal Help Text Link"
        end
      end

      it "renders additional label content" do
        expect(subject).to have_css ".Link-content", text: "Normal Help Text Link"
      end
    end

    context "with an additional styled label" do
      let(:block) do
        proc do |help_text|
          help_text.with_additional_label(font_weight: :bold) { "Bold Help Text Link" }
        end
      end

      it "renders additional label content" do
        expect(subject).to have_css ".Link-content", text: "Bold Help Text Link"
        expect(subject).to have_css ".text-bold", text: "Bold Help Text Link"
      end
    end
  end

  shared_examples "component does not render" do
    it "renders nothing" do
      expect(subject).to have_no_element
    end

    it "does not raise an error" do
      expect { subject }.not_to raise_error
    end
  end

  context "with a project help text" do
    let(:help_text) { build_stubbed(:project_help_text, attribute_name:) }

    context "for a default attribute" do
      let(:attribute_name) { :name }

      it_behaves_like "component renders"
    end

    context "for a project attribute" do
      let(:attribute_name) { :custom_field_2105 }

      it_behaves_like "component renders"
    end
  end

  context "with a work package help text" do
    let(:help_text) { build_stubbed(:work_package_help_text, attribute_name:) }

    context "for a default attribute" do
      let(:attribute_name) { :subject }

      it_behaves_like "component renders"
    end

    context "for a custom field attribute" do
      let(:attribute_name) { :custom_field_99 }

      it_behaves_like "component renders"
    end
  end

  context "with nil help text" do
    let(:help_text) { nil }

    it_behaves_like "component does not render"
  end
end
