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

RSpec.describe Projects::Settings::WorkPackages::Types::InUseMarkerComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(label: "Variant in this project")) }

  it "says what is in use" do
    expect(rendered_component).to have_text("Variant in this project")
  end

  it "checks it off, so the reader finds it without reading" do
    expect(rendered_component).to have_css(".octicon-check-circle-fill")
  end

  it "sets the words in the colour that means so" do
    expect(rendered_component).to have_css(".color-fg-success", text: "Variant in this project")
  end

  # A statement of fact rather than something to notice: a header's title slot would otherwise lend
  # it the type name's weight.
  it "does not emphasise it" do
    expect(rendered_component).to have_css(".text-normal", text: "Variant in this project")
  end

  # The lists that show it assert on this rather than on the markup above.
  it "is addressable by its own test selector" do
    expect(rendered_component).to have_css("[data-test-selector='in-use-marker']", text: "Variant in this project")
  end
end
