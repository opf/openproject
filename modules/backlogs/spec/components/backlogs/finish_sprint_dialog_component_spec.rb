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

RSpec.describe Backlogs::FinishSprintDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:admin) { create(:admin) }
  current_user { admin }

  let(:project) { create(:project) }
  let(:sprint) { create(:sprint, project:, name: "Sprint 1", status: "active") }
  let(:available_sprints) { [] }

  def render_component
    render_inline(described_class.new(sprint:, project:, available_sprints:))
  end

  it "renders the finish sprint dialog title" do
    render_component

    expect(page).to have_text(I18n.t("backlogs.finish_sprint_dialog_component.title"))
  end

  it "renders the form targeting the finish sprint path" do
    render_component

    expect(page).to have_element(:form, action: finish_project_backlogs_sprint_path(project, sprint))
  end

  it "does not include the all parameter in the form action by default" do
    render_component

    expect(page).to have_no_css("form[action*='all=']", visible: :all)
  end

  context "when params[:all] is true" do
    before { vc_test_controller.params[:all] = "1" }

    it "propagates the all parameter in the form action" do
      render_component

      expect(page)
        .to have_element(:form, action: finish_project_backlogs_sprint_path(project, sprint, all: true))
    end
  end
end
