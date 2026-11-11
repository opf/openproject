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

RSpec.describe Help::ProjectLifeCycleDialogComponent, type: :component do
  before { render_inline(described_class.new(show_button: true)) }

  it "uses the existing Primer modal with the floating reader layout" do
    expect(page).to have_css("dialog.contextual-help-dialog##{described_class::DIALOG_ID}", visible: :all)
  end

  it "loads the repository article when opened" do
    expect(page).to have_css('turbo-frame[src*="/help/documentation/project-life-cycle"][loading="lazy"]', visible: :all)
  end

  it "provides a labelled trigger and dialog", :aggregate_failures do
    expect(page).to have_button(I18n.t("contextual_help.life_cycle.open"))
    expect(page).to have_css("dialog[aria-labelledby]", visible: :all)
  end

  it "gives project initiation help a separate dialog and frame" do
    render_inline(Help::DocumentationDialogComponent.new(context: "initiation", show_button: true))
    expect(page).to have_css("dialog##{Help::DocumentationDialogComponent.dialog_id('initiation')}", visible: :all)
    expect(page).to have_css('turbo-frame[src*="/help/documentation/initiation-request"]', visible: :all)
  end
end
