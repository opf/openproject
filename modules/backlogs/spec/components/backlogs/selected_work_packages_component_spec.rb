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

RSpec.describe Backlogs::SelectedWorkPackagesComponent, type: :component do
  shared_let(:admin) { create(:admin) }
  current_user { admin }

  shared_let(:project) { create(:project) }
  shared_let(:epic_type) { create(:type, name: "Epic") }
  shared_let(:feature_type) { create(:type, name: "Feature") }
  shared_let(:epic) { create(:work_package, project:, type: epic_type, subject: "Contamination model") }
  shared_let(:feature) { create(:work_package, project:, type: feature_type, subject: "Warning system") }

  let(:description_id) { "move-dialog-selection" }

  def render_component(work_packages: [feature, epic])
    render_inline(described_class.new(work_packages:, description_id:))
  end

  it "labels the box and names every work package in the given order", :aggregate_failures do
    render_component

    expect(page).to have_text(I18n.t("backlogs.selected_work_packages_component.label"))
    expect(page.text).to match(
      /Feature.*#{feature.formatted_id}.*Warning system.*Epic.*#{epic.formatted_id}.*Contamination model/mi
    )
  end

  it "links each work package to its full view" do
    render_component

    expect(page).to have_link(feature.formatted_id, href: "/work_packages/#{feature.id}")
    expect(page).to have_link(epic.formatted_id, href: "/work_packages/#{epic.id}")
  end

  # The visible list replaces the count, so the count only reaches a screen
  # reader through the hidden element the acting control describes itself by.
  it "keeps the selected count on a hidden description element" do
    render_component

    expect(page).to have_css(
      "##{description_id}[hidden]",
      text: I18n.t(:label_x_work_packages, count: 2),
      visible: :all
    )
  end
end
