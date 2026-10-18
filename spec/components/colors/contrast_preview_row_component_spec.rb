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

RSpec.describe Colors::ContrastPreviewRowComponent, type: :component do
  subject(:rendered_component) do
    render_inline(described_class.new(mode: "light", usage: "foreground", hexcode_id: "color_hexcode"))
  end

  it "lists the colour values as a definition list", :aggregate_failures do
    expect(rendered_component).to have_element :dl do |list|
      expect(list).to have_element :dt, text: "Text"
      expect(list).to have_element :dd, "data-contrast-value": "foreground"
      expect(list).to have_element :dt, text: "Background"
      expect(list).to have_element :dd, "data-contrast-value": "background"
    end
  end

  it "reports the verdict and ratio as a quiet output of the hex code" do
    expect(rendered_component).to have_element :output, for: "color_hexcode", "aria-live": "off" do |output|
      expect(output).to have_element :span, "data-contrast-verdict": "pass", visible: :all
      expect(output).to have_element :span, "data-contrast-verdict": "fail", visible: :all
      expect(output).to have_element :span, "data-contrast-value": "ratio"
    end
  end
end
