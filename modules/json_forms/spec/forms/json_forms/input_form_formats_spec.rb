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

require "spec_helper"

RSpec.describe JsonForms::InputForm, "formats", type: :forms do
  include_context "with rendered form"

  let(:model) { JsonForms::InputForm::ValuelessModel.new }
  let(:form_arguments) { { url: "/foo", model:, scope: :input } }
  let(:schema) do
    { "type" => "object",
      "properties" => { "version" => { "type" => "string", "title" => "Version", "format" => "op-version" },
                        "color" => { "type" => "string", "title" => "Color", "format" => "test-color" } } }
  end
  let(:context) { {} }
  let(:params) { { schema:, data: { "version" => version.id.to_s }, context: } }

  shared_let(:project) { create(:project) }
  shared_let(:version) { create(:version, project:, name: "Release 1") }

  subject(:rendered_form) do
    vc_render_form
    page
  end

  it "registers OpenProject's formats" do
    expect(JsonForms::Formats.for("op-user")).to eq JsonForms::Formats::UserAutocompleter
    expect(JsonForms::Formats.for("op-work-package")).to eq JsonForms::Formats::WorkPackageAutocompleter
    expect(JsonForms::Formats.for("op-version")).to eq JsonForms::Formats::VersionSelect
    expect(JsonForms::Formats.for("date")).to eq JsonForms::Formats::DatePicker
  end

  it "renders unknown formats as text fields" do
    expect(rendered_form).to have_field "Color", type: :text, name: "input[color]"
  end

  context "with the project in the context" do
    let(:context) { { project: } }

    it "offers the project's versions" do
      expect(rendered_form).to have_select "Version", selected: "Release 1", name: "input[version]"
    end
  end

  context "with a registered renderer" do
    around do |example|
      JsonForms::Formats.register("test-color", ->(container, value:, arguments:, context:) do
        container.text_field(**arguments, type: :color, value:, caption: context[:hint])
      end)
      example.run
    ensure
      JsonForms::Formats.renderers.delete("test-color")
    end

    let(:context) { { hint: "Pick a color" } }

    it "renders the format with it, passing the arguments and context" do
      expect(rendered_form).to have_field "Color", type: :color, name: "input[color]"
      expect(rendered_form).to have_text "Pick a color"
    end
  end
end
