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

require_relative "../spec_helper"

RSpec.describe CostEntry, "#editable_by? with reassigned ownership" do
  include Cost::PluginSpecHelper

  let(:project) { create(:project_with_types) }
  let(:victim) { create(:user) }
  let(:acting_user) { create(:user) }
  let(:work_package) do
    create(:work_package, project:, author: victim, type: project.enabled_types.first)
  end
  let(:cost_entry) do
    create(:cost_entry, entity: work_package, project:, user: victim)
  end

  before do
    is_member(project, acting_user, [:edit_own_cost_entries])
  end

  it "is not editable after reassignment to the acting user within the same request" do
    cost_entry.user = acting_user

    expect(cost_entry.editable_by?(acting_user)).to be(false)
  end
end
