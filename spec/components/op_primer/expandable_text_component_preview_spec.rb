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
require Rails.root.join("lookbook/previews/op_primer/expandable_text_component_preview").to_s

RSpec.describe OpPrimer::ExpandableTextComponentPreview, type: :component do
  # TODO: replace this path shim with a cleaner mechanism for exercising
  # lookbook previews in specs (e.g. a shared support helper).
  #
  # Lookbook is disabled in the test environment, so its preview path (which hosts the
  # `render_with_template` ERB files) is not registered. Register it for these examples so
  # `render_preview` can resolve the templates, then restore the original paths.
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

  it "renders the default (single-line) preview" do
    render_preview(:default, from: described_class)

    expect(page).to have_css("[data-controller='expandable-text'][data-expandable-text-mode-value='single_line']")
    expect(page).to have_css(".Truncate[data-expandable-text-target='truncate']")
  end

  it "renders the hidden_for_short_texts preview" do
    render_preview(:hidden_for_short_texts, from: described_class)

    expect(page).to have_css("[data-controller='expandable-text']", text: "Short text")
  end

  it "renders the in_table preview" do
    render_preview(:in_table, from: described_class)

    expect(page).to have_css("table [data-controller='expandable-text']")
    expect(page).to have_text("Automatically managed project folders")
  end

  it "renders the multi_line preview with a configurable line count" do
    render_preview(:multi_line, from: described_class, params: { lines: 4 })

    expect(page).to have_css("[data-expandable-text-mode-value='multi_line']")
    expect(page).to have_css(".op-vertical-truncate--lines-4[data-expandable-text-target='truncate']")
  end

  it "renders the dialog preview (inline: false)" do
    render_preview(:dialog, from: described_class)

    expect(page).to have_css("[data-expandable-text-inline-value='false']")
    expect(page).to have_css("#expandable-text-dialog", visible: :all)
  end

  it "renders the playground preview" do
    render_preview(:playground, from: described_class, params: { truncate: "multi_line", lines: 2 })

    expect(page).to have_css("[data-controller='expandable-text'][data-expandable-text-mode-value='multi_line']")
    expect(page).to have_css(".op-vertical-truncate--lines-2[data-expandable-text-target='truncate']")
  end
end
