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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Exports::PDF::ZendisArtefact::Styles::PDFStyles do
  subject(:styles) { described_class.new }

  let(:style_file) { Rails.root.join("app/models/exports/pdf/zendis_artefact/standard.yml").to_s }
  let(:configuration) { YAML.load_file(style_file) }

  before do
    allow(YAML).to receive(:load_file).and_call_original
    allow(YAML).to receive(:load_file).with(style_file).and_return(configuration)
  end

  it "resolves changed font and table styles from the style file" do
    configuration["cover"]["heading"]["size"] = 21
    configuration["section"]["title"]["background_color"] = "112233"
    configuration["section"]["title"]["padding_left"] = 9

    expect(styles.cover_heading).to include(size: 21, styles: [:bold])
    expect(styles.section_title_cell).to include(background_color: "112233", padding_left: 9)
    expect(styles.cover_heading).not_to have_key(:font)
  end

  it "rejects unknown layout settings" do
    configuration["layout"]["unknown_setting"] = 10

    expect { styles }.to raise_error(MarkdownToPDF::StyleValidation::StyleValidationError, /unknown_setting/)
  end

  it "rejects a cover heading position outside the page" do
    configuration["layout"]["cover_heading_position"] = 1.5

    expect { styles }.to raise_error(MarkdownToPDF::StyleValidation::StyleValidationError, /cover_heading_position/)
  end
end
