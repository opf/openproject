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

RSpec.describe Admin::Import::Jira::ImportRuns::ImportedStatsBannerComponent, type: :component do
  let(:stats) do
    [
      { label: "Projects", value: 3, subtitle: "Imported into OpenProject" },
      { label: "Work packages", value: 2748, subtitle: "With attachments" }
    ]
  end

  it "renders the title on a success-colored panel" do
    render_inline(described_class.new(title: "Data imported", stats:))

    expect(page).to have_css(".color-bg-success")
    expect(page).to have_css("h3", text: "Data imported")
  end

  it "renders one stat card per entry with label, value and subtitle" do
    render_inline(described_class.new(title: "Data imported", stats:))

    expect(page).to have_text("Projects")
    expect(page).to have_text("3")
    expect(page).to have_text("Work packages")
    expect(page).to have_text("2748")
    expect(page).to have_text("With attachments")
  end

  it "links a tile to its url, opening in a new tab, when url is present" do
    linked_stats = [
      { label: "Projects", value: 3, subtitle: "Imported into OpenProject", url: "/projects" },
      { label: "Work packages", value: 2748, subtitle: "With attachments" }
    ]
    render_inline(described_class.new(title: "Data imported", stats: linked_stats))

    expect(page).to have_css('a[href="/projects"][target="_blank"]', text: "Projects")
    expect(page).to have_no_css("a", text: "Work packages")
  end

  it "does not link tiles when url is blank" do
    render_inline(described_class.new(title: "Data imported", stats:))

    expect(page).to have_no_css("a")
  end

  it "renders no stat cards when stats is empty" do
    render_inline(described_class.new(title: "Data imported", stats: []))

    expect(page).to have_css("h3", text: "Data imported")
    expect(page).to have_no_text("Projects")
  end
end
