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

RSpec.describe Projects::NewComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:params) { {} }

  subject(:rendered_component) { render_inline(described_class.new(project:, **params)) }

  it "renders a form" do
    expect(rendered_component).to have_css "form"
  end

  describe "action" do
    let(:project) { Project.new(workspace_type:) }

    [
      ["not set",               nil,        "/projects"],
      ["set to unknown value",  :unknown,   "/projects"],
      ["set to project",        :project,   "/projects"],
      ["set to program",        :program,   "/programs"],
      ["set to portfolio",      :portfolio, "/portfolios"]
    ].each do |condition, value, expected_path|
      context "when workspace type is #{condition}" do
        let(:workspace_type) { value }

        it "sets action to create project" do
          expect(rendered_component).to have_element :form do |form|
            expect(form["action"]).to eq expected_path
          end
        end
      end
    end
  end

  context "when creating from scratch" do
    it "renders custom fields form" do
      allow(Projects::Settings::CustomFieldsForm).to receive(:new).and_call_original
      rendered_component
      expect(Projects::Settings::CustomFieldsForm).to have_received(:new)
    end
  end

  context "when creating from template" do
    let(:params) { { template:, copy_options: } }
    let(:template) { build_stubbed(:template_project) }
    let(:copy_options) { Projects::CopyOptions.new }

    it "renders custom fields form" do
      allow(Projects::Settings::CustomFieldsForm).to receive(:new).and_call_original
      rendered_component
      expect(Projects::Settings::CustomFieldsForm).to have_received(:new)
    end
  end

  describe "#identifier_suggestion_data" do
    it_behaves_like "renders identifier_suggestion_data"
  end
end
