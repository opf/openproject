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

RSpec.describe WorkPackages::Exports::Generate::Templates::WikiPagesFieldsComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(refs:, disabled:, context:)) }

  shared_let(:provider) { create(:internal_wiki_provider) }
  shared_let(:project) { create(:project, name: "Arcanos") }
  shared_let(:wiki) { create(:wiki, project:) }
  shared_let(:wiki_page) { create(:wiki_page, wiki:, title: "Legal information") }

  let(:refs) { [WorkPackage::PDFExport::WikiPageRef.new(provider_id: provider.id.to_s, identifier: wiki_page.id.to_s)] }
  let(:disabled) { false }
  let(:context) { :configuration }

  it "renders the add button opening the picker dialog" do
    expect(rendered_component).to have_css("[data-show-dialog-id='#{described_class::DIALOG_ID}']")
    expect(rendered_component).to have_text "Add wiki pages"
  end

  it "warns that configuring a page shares it with every reader" do
    expect(rendered_component).to have_css(".Banner", text: /visible to everyone who can export/)
  end

  it "hands the configured page to the draggable autocompleter, project qualified" do
    expect(autocompleter_inputs["selected"])
      .to eq [{ "id" => "#{provider.id}:#{wiki_page.id}", "name" => "Arcanos: Legal information" }]
  end

  it "lets the autocompleter own the field, submitting one value per entry" do
    expect(autocompleter_inputs["name"]).to eq "wiki_pages[]"
    expect(autocompleter_inputs["inputHidden"]).to be true
  end

  it "submits an empty value so clearing the list clears the setting" do
    expect(rendered_component).to have_css("input[type=hidden][name='wiki_pages[]'][value='']", visible: :all)
  end

  context "when a referenced page no longer exists" do
    let(:refs) { [WorkPackage::PDFExport::WikiPageRef.new(provider_id: provider.id.to_s, identifier: "0")] }

    it "flags the entry instead of dropping it" do
      expect(autocompleter_inputs["selected"])
        .to eq [{ "id" => "#{provider.id}:0", "name" => "Unavailable wiki page (#{provider.id}:0)" }]
    end
  end

  context "when the configuration is read only" do
    let(:disabled) { true }

    it "renders no picker, protects the entries and omits the clearing sentinel" do
      expect(rendered_component).to have_no_css("[data-show-dialog-id]")
      expect(autocompleter_inputs["protected"]).to eq autocompleter_inputs["selected"]
      expect(rendered_component).to have_no_css("input[type=hidden][name='wiki_pages[]'][value='']", visible: :all)
    end
  end

  context "when rendered in the Generate PDF dialog" do
    let(:context) { :export }

    it "omits the visibility notice" do
      expect(rendered_component).to have_no_css(".Banner")
      expect(rendered_component).to have_no_text(/visible to everyone who can export/)
    end
  end

  def autocompleter_inputs
    element = rendered_component.at_css("opce-draggable-autocompleter")

    %w[selected name inputHidden protected].index_with do |input|
      value = element["data-#{input.underscore.dasherize}"]
      JSON.parse(value) unless value.nil?
    end
  end
end
