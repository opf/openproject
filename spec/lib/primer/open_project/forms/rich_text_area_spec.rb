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
#
require "spec_helper"

RSpec.describe Primer::OpenProject::Forms::RichTextArea, type: :forms do
  include ViewComponent::TestHelpers

  let(:params) { { rich_text_options: {} } }
  let(:model) { build_stubbed(:comment) }

  def render_form
    render_in_view_context(model, namespace, params) do |model, namespace, params|
      primer_form_with(url: "/foo", model:, namespace:) do |f|
        render_inline_form(f) do |test_form|
          test_form.rich_text_area(name: :ultimate_answer, label: "Ultimate answer", **params)
        end
      end
    end
  end

  subject(:rendered_form) do
    render_form
    page
  end

  shared_examples_for "successful render" do |text_area_id:|
    it "renders the label" do
      expect(rendered_form).to have_element :label, for: text_area_id
    end

    it "renders the hidden textarea" do
      expect(rendered_form).to have_field text_area_id, type: "textarea", visible: :hidden
    end

    it "renders the rich text area" do
      expect(rendered_form).to have_element "opce-ckeditor-augmented-textarea",
                                            "data-text-area-id": text_area_id.to_json
    end
  end

  context "without form namespace" do
    let(:namespace) { nil }

    context "with default field id" do
      it_behaves_like "successful render", text_area_id: "comment_ultimate_answer"
    end

    context "without prefixing model name" do
      let(:params) { { scope_id_to_model: false, rich_text_options: {} } }

      it "renders the label" do
        expect(rendered_form).to have_element :label, for: "ultimate_answer"
      end

      it "renders the hidden textarea" do
        expect(rendered_form).to have_field "ultimate_answer", type: "textarea", visible: :hidden
      end

      it "renders the rich text area" do
        expect(rendered_form).to have_element "opce-ckeditor-augmented-textarea",
                                              "data-text-area-id": "ultimate_answer".to_json
      end
    end

    context "with explicit field id" do
      let(:params) { { id: "explicit_id", rich_text_options: {} } }

      it_behaves_like "successful render", text_area_id: "explicit_id"
    end
  end

  context "with form namespace" do
    let(:namespace) { "super_form" }

    context "with default field id" do
      it_behaves_like "successful render", text_area_id: "super_form_comment_ultimate_answer"
    end

    context "without prefixing model name" do
      let(:params) { { scope_id_to_model: false, rich_text_options: {} } }

      it "renders the label" do
        expect(rendered_form).to have_element :label, for: "super_form_ultimate_answer"
      end

      it "renders the hidden textarea" do
        expect(rendered_form).to have_field "super_form_ultimate_answer", type: "textarea", visible: :hidden
      end

      it "renders the rich text area" do
        expect(rendered_form).to have_element "opce-ckeditor-augmented-textarea",
                                              "data-text-area-id": "super_form_ultimate_answer".to_json
      end
    end

    context "with explicit field id" do
      let(:params) { { id: "explicit_id", rich_text_options: {} } }

      it_behaves_like "successful render", text_area_id: "super_form_explicit_id"
    end
  end
end
