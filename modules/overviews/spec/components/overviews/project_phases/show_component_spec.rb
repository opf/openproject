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

RSpec.describe Overviews::ProjectPhases::ShowComponent, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { build(:project) }
  let!(:project_phases) { create_list(:project_phase, 2, project:) }
  let(:user) { create(:user, member_with_permissions: { project => [:view_project_phases] }) }

  current_user { user }

  subject(:rendered_component) do
    render_component(project:)
  end

  it "renders a section" do
    expect(rendered_component).to have_section "Project life cycle"
  end

  it "renders two project life cycles" do
    expect(rendered_component).to have_css ".op-project-life-cycle-container", count: 2
  end
end
