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

RSpec.describe OpenProject::Common::AttributeLabelComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:attribute) { "name" }
  let(:model) { create(:project) }
  let(:required) { false }
  let(:tag) { :span }
  let(:current_user) { create(:user) }
  let(:content) { "Name" }

  subject do
    render_inline(described_class.new(attribute:, model:, tag:, current_user:, required:)) do
      content
    end

    page
  end

  shared_examples "component renders" do
    context "without a wrapper" do
      let(:tag) { nil }

      it "renders no wrapper" do
        expect(subject).to have_no_element class: "op-attribute-label"
      end
    end

    context "with a wrapper" do
      let(:tag) { :div }

      it "applies .op-attribute-label class" do
        expect(subject).to have_element :div, class: "op-attribute-label"
      end
    end

    it "renders content" do
      expect(subject).to have_text "Name"
    end

    context "with a required field" do
      let(:required) { true }

      it "renders a required star" do
        expect(subject).to have_text "*"
      end
    end
  end

  context "without help text" do
    it_behaves_like "component renders"

    it "does not render help text" do
      expect(subject).to have_no_element class: "op-attribute-help-text"
    end
  end

  context "with help text on an attribute" do
    let!(:help_text) { create(:project_help_text, attribute_name: attribute) }

    it_behaves_like "component renders"

    it "renders help text" do
      expect(subject).to have_element class: "op-attribute-help-text"
    end
  end

  context "with help text on an association" do
    let(:attribute) { "parent_id" }
    let!(:help_text) { create(:project_help_text, attribute_name: attribute) }

    it_behaves_like "component renders"

    it "renders help text" do
      expect(subject).to have_element class: "op-attribute-help-text"
    end
  end
end
