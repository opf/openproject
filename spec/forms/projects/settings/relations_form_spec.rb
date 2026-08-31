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

RSpec.describe Projects::Settings::RelationsForm, type: :forms do
  include_context "with rendered form"

  let(:model) { build_stubbed(:project, parent:, workspace_type:) }
  let(:parent) { nil }
  let(:workspace_type) { :project }

  %i[program project].each do |workspace_type|
    context "for workspace type #{workspace_type}" do
      let(:workspace_type) { workspace_type }

      it "renders field" do
        expect(page).to have_element "opce-project-autocompleter", "data-input-name": "\"project[parent_id]\""
      end
    end
  end

  context "for workspace type portfolio" do
    let(:workspace_type) { "portfolio" }

    it "does not render" do
      expect(page).not_to have_element "opce-project-autocompleter", "data-input-name": "\"project[parent_id]\""
    end
  end

  context "without parent" do
    it "renders field with model" do
      expect(page).to have_element "opce-project-autocompleter", "data-test-selector": "parent" do |element|
        expect(element["data-model"]).to be_json_eql(nil.to_json)
      end
    end
  end

  context "with parent" do
    let(:parent) { build_stubbed(:project, public:, name: "New Project") }
    let(:public) { false }

    context "when the parent is not visible to the user" do
      it "renders field with model" do
        expect(page).to have_element "opce-project-autocompleter", "data-test-selector": "parent" do |element|
          expect(element["data-model"]).to be_json_eql(
            %{{"name": "Undisclosed - The parent is invisible because of lacking permissions."}}
          )
        end
      end
    end

    context "when the parent is visible to the user (e.g. public)" do
      let(:public) { true }

      it "renders field with model" do
        expect(page).to have_element "opce-project-autocompleter", "data-test-selector": "parent" do |element|
          expect(element["data-model"]).to be_json_eql(%{{"name": "New Project"}})
        end
      end
    end

    context "when the user is an admin" do
      before do
        allow(User).to receive(:current).and_return(build_stubbed(:admin))
        render_form
      end

      it "renders field with model" do
        expect(page).to have_element "opce-project-autocompleter", "data-test-selector": "parent" do |element|
          expect(element["data-model"]).to be_json_eql(%{{"name": "New Project"}})
        end
      end
    end
  end

  context "with validation errors" do
    before do
      model.errors.add(:parent, :invalid)
      render_form
    end

    it "renders error message" do
      expect(page).to have_css ".FormControl-inlineValidation", text: "Subproject of is invalid"
    end
  end
end
