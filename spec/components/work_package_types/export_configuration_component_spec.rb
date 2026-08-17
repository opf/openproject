# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

require "rails_helper"

RSpec.describe WorkPackageTypes::ExportConfigurationComponent, type: :component do
  let(:type) { create(:type) }
  let(:variant) { type.default_variant }

  context "when readonly" do
    it "hides the enable-all / disable-all actions", :aggregate_failures do
      render_inline(described_class.new(variant, readonly: true))

      expect(page).to have_no_css("[data-test-selector='enable-all-pdf-export-templates']")
      expect(page).to have_no_css("[data-test-selector='disable-all-pdf-export-templates']")
    end

    it "renders the inherited artefact export mode as disabled radios" do
      render_inline(described_class.new(variant, readonly: true))

      expect(page.find("input[type=radio][value='#{Type::ArtefactExport::OFF}']")).to be_disabled
    end
  end

  context "when editable (default)" do
    it "shows the enable-all action" do
      render_inline(described_class.new(variant))

      expect(page).to have_css("[data-test-selector='enable-all-pdf-export-templates']")
    end

    it "renders the artefact export mode as editable radios" do
      render_inline(described_class.new(variant))

      expect(page.find("input[type=radio][value='#{Type::ArtefactExport::OFF}']")).not_to be_disabled
    end
  end
end
