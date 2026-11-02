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

  it "renders the right-side overlay used for avatar settings" do
    expect(page).to have_css("dialog.Overlay--placement-right##{described_class::DIALOG_ID}", visible: :all)
  end

  it "combines the methodology with concrete OpenProject steps", :aggregate_failures do
    expect(page).to have_heading(I18n.t("contextual_help.project_life_cycle.purpose_heading"), visible: :all)
    expect(page).to have_heading(I18n.t("contextual_help.project_life_cycle.steps_heading"), visible: :all)
    expect(page).to have_css("dl dt", count: 4, visible: :all)
    expect(page).to have_css("ol li", count: 4, visible: :all)
  end

  it "provides an accessible trigger, title and close button", :aggregate_failures do
    expect(page).to have_button(I18n.t("contextual_help.open"))
    expect(page).to have_css("dialog[aria-labelledby]", visible: :all)
    expect(page).to have_button(I18n.t(:button_close), visible: :all)
  end
end
