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

require "rails_helper"
require Rails.root.join("lookbook/previews/open_project/common/border_box_list_component_preview").to_s

RSpec.describe OpenProject::Common::BorderBoxListComponentPreview, type: :component do
  it "renders a realistic default preview description" do
    render_preview(:default, from: described_class)

    expect(page).to have_text("Coordinate launch work and keep stakeholders aligned.")
  end

  it "renders the default preview with the provided description text" do
    render_preview(
      :default,
      from: described_class,
      params: {
        description: "Default preview description that demonstrates how text wraps near the header action buttons."
      }
    )

    expect(page).to have_text(
      "Default preview description that demonstrates how text wraps near the header action buttons."
    )
  end

  it "renders a realistic transparent preview description" do
    render_preview(:transparent, from: described_class)

    expect(page).to have_text("Sprint goals, scope, and timing for the next iteration.")
  end

  it "renders the transparent preview with the provided description text" do
    render_preview(
      :transparent,
      from: described_class,
      params: {
        description: "Transparent preview description that demonstrates how text wraps near the sprint action buttons."
      }
    )

    expect(page).to have_text(
      "Transparent preview description that demonstrates how text wraps near the sprint action buttons."
    )
  end

  it "renders the playground preview with the provided description text" do
    render_preview(
      :playground,
      from: described_class,
      params: {
        description: "A longer playground description that demonstrates wrapping behavior in the list header preview."
      }
    )

    expect(page).to have_text(
      "A longer playground description that demonstrates wrapping behavior in the list header preview."
    )
  end

  it "renders the playground preview with a header padding override" do
    render_preview(
      :playground,
      from: described_class,
      params: {
        padding: :condensed,
        header_padding: :default
      }
    )

    expect(page).to have_css(".Box.Box--condensed.op-border-box-list_header-padding-default")
  end
end
