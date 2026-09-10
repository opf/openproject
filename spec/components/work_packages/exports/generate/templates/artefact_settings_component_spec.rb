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

RSpec.describe WorkPackages::Exports::Generate::Templates::ArtefactSettingsComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(settings:, disabled:)) }

  let(:settings) { { toc: true, hyphenation: false, hyphenation_language: "en" } }
  let(:disabled) { false }

  it "renders the toc checkbox checked" do
    expect(rendered_component).to have_checked_field "Table of contents"
  end

  it "renders the hyphenation checkbox unchecked and the language pre-selected" do
    expect(rendered_component).to have_unchecked_field "Hyphenation"
    expect(rendered_component).to have_css("select[name='hyphenation_language'] option[value='en'][selected]",
                                           visible: :all)
  end

  context "when toc is false" do
    let(:settings) { { toc: false } }

    it "renders the toc checkbox unchecked" do
      expect(rendered_component).to have_unchecked_field "Table of contents"
    end
  end

  context "when hyphenation is enabled" do
    let(:settings) { { hyphenation: true, hyphenation_language: "de" } }

    it "renders the hyphenation checkbox checked with German selected" do
      expect(rendered_component).to have_checked_field "Hyphenation"
      expect(rendered_component).to have_css("select[name='hyphenation_language'] option[value='de'][selected]",
                                             visible: :all)
    end
  end

  context "when toc and hyphenation are stored as the string" do
    let(:settings) { { toc: "true", hyphenation: "true" } }

    it "renders the toc and hyphenation checkboxes checked" do
      expect(rendered_component).to have_checked_field "Table of contents"
      expect(rendered_component).to have_checked_field "Hyphenation"
    end
  end

  context "when settings is empty" do
    let(:settings) { {} }

    it "renders the toc checkbox with the exporter's default and hyphenation unchecked" do
      expect(rendered_component).to have_field "Table of contents",
                                               checked: WorkPackage::PDFExport::Artefact::DEFAULT_TOC
      expect(rendered_component).to have_unchecked_field "Hyphenation"
    end

    it "preselects no hyphenation language so the export keeps falling back to the current locale" do
      expect(rendered_component).to have_css("select[name='hyphenation_language'] option[value=''][selected]",
                                             visible: :all)
    end
  end

  context "when disabled" do
    let(:disabled) { true }

    it "renders every field disabled" do
      expect(rendered_component).to have_field "Table of contents", disabled: true
      expect(rendered_component).to have_field "Hyphenation", disabled: true
      expect(rendered_component).to have_select "hyphenation_language", disabled: true
    end
  end
end
