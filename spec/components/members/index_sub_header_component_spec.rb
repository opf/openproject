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

RSpec.describe Members::IndexSubHeaderComponent, type: :component do
  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:filter_options) do
    { groups: [], roles: [], shares: [], status: "all", clear_url: "/projects/#{project.identifier}/members", project: }
  end

  current_user { user }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project :manage_members, project:
    end
  end

  def render_component(roles_available:)
    with_request_url "/projects/#{project.identifier}/members" do
      render_inline(described_class.new(project:, filter_options:, roles_available:))
    end
  end

  it "renders the add member button when there are roles to assign" do
    render_component(roles_available: true)

    expect(page).to have_button("Member")
  end

  it "does not render the add member button without roles to assign" do
    render_component(roles_available: false)

    expect(page).to have_no_button("Member")
  end
end
