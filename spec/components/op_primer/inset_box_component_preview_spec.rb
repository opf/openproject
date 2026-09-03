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
require Rails.root.join("lookbook/previews/op_primer/inset_box_component_preview").to_s

RSpec.describe OpPrimer::InsetBoxComponentPreview, type: :component do
  # Lookbook is disabled in the test environment, so its preview path is not registered.
  # Register it for these examples, then restore the original paths.
  around do |example|
    path = Rails.root.join("lookbook/previews").to_s
    paths = ViewComponent::Base.previews.paths
    added = paths.exclude?(path)
    paths << path if added
    begin
      example.run
    ensure
      paths.delete(path) if added
    end
  end

  it "renders the playground with a title icon" do
    render_preview(:playground, from: described_class,
                                params: { scheme: :warning, title_icon: :alert, title: "Careful" })

    expect(page).to have_css(".color-bg-attention .octicon-alert + h3", text: "Careful")
  end

  it "renders the playground with a single action button" do
    render_preview(:playground, from: described_class, params: { action: :button })

    expect(page).to have_button("Primary action")
  end

  it "renders the playground with two action buttons" do
    render_preview(:playground, from: described_class, params: { action: :buttons })

    expect(page).to have_button("Secondary action")
    expect(page).to have_button("Primary action")
  end

  it "renders the playground with an action menu" do
    render_preview(:playground, from: described_class, params: { action: :menu })

    expect(page).to have_button("Actions")
    expect(page).to have_text("First action")
  end

  it "renders the playground without an action" do
    render_preview(:playground, from: described_class, params: { action: :none })

    expect(page).to have_no_button
  end

  it "renders the playground without a title icon" do
    render_preview(:playground, from: described_class, params: { title_icon: :none })

    expect(page).to have_css("h3", text: "Inset box title")
    expect(page).to have_no_css(".octicon")
  end

  it "renders the scheme previews" do
    render_preview(:warning, from: described_class)

    expect(page).to have_css(".color-bg-attention.color-border-attention")
    expect(page).to have_css(".octicon-alert + h3", text: "Careful")
  end

  it "renders the info preview" do
    render_preview(:info, from: described_class)

    expect(page).to have_css(".color-bg-accent.color-border-accent")
  end

  it "renders the title preview" do
    render_preview(:with_title, from: described_class)

    expect(page).to have_css("h3", text: "Reuse mode")
  end

  it "renders the title icon preview" do
    render_preview(:with_title_icon, from: described_class)

    expect(page).to have_css(".octicon-link + h3", text: "Inherited configuration")
  end

  it "renders the action buttons preview" do
    render_preview(:with_action_buttons, from: described_class)

    expect(page).to have_button("Change source type")
    expect(page).to have_button("Configure manually")
  end

  it "renders the action menu preview" do
    render_preview(:with_action_menu, from: described_class)

    expect(page).to have_button("Actions")
    expect(page).to have_text("View dependent types")
  end
end
