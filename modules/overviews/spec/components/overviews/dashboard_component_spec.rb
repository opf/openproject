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

RSpec.describe Overviews::DashboardComponent, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }

  current_user { user }

  subject(:rendered_component) do
    render_component(project:, current_user:)
  end

  it "renders widgets" do
    expect(rendered_component).to have_element "opce-dashboard"
  end

  context "when user is not allowed to manage" do
    it "does not render '+ Widget' button" do
      expect(rendered_component).to have_no_button "Widget"
    end
  end

  context "when user is allowed to manage" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:manage_dashboards, project:)
      end
    end

    it "renders '+ Widget' button" do
      expect(rendered_component).to have_button "Widget" do |button|
        expect(button).to have_octicon :plus
        expect(button["data-action"]).to include "click->overview--add-widgets#addWidget"
      end
    end
  end
end
