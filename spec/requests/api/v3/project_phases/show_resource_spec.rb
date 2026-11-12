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

require "spec_helper"

RSpec.describe API::V3::ProjectPhases::ProjectPhasesAPI, "show", content_type: :json do # rubocop:disable RSpec/SpecFilePathFormat
  include API::V3::Utilities::PathHelper

  shared_let(:user) { create(:user) }
  shared_let(:role) { create(:project_role, permissions: %i(view_project_phases)) }
  shared_let(:project) do
    create(:project,
           members: { user => role })
  end
  shared_let(:project_phase) { create(:project_phase, project:) }

  let(:send_request) do
    get api_v3_paths.project_phase(project_phase.id)
  end

  current_user { user }

  context "with an authorized user" do
    before do
      send_request
    end

    it_behaves_like "successful response"
  end

  context "with an unauthorized user" do
    before do
      role.permissions = role.permissions - [:view_project_phases]
      role.save!

      send_request
    end

    it_behaves_like "not found"
  end
end
