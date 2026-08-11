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

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Backlogs::Sprints::StartContract do
  include_context "ModelContract shared context"

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:sprint) do
    create(:sprint,
           project:,
           status: sprint_status)
  end
  let(:sprint_status) { "in_planning" }
  let(:permissions) { [:start_complete_sprint] }

  subject(:contract) { described_class.new(sprint, user) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project(*permissions, project:)
    end
  end

  describe "validation" do
    context "with valid sprint and permissions" do
      it_behaves_like "contract is valid"
    end

    context "without start_complete_sprint permission" do
      let(:permissions) { [:view_work_packages] }

      it_behaves_like "contract user is unauthorized"
    end

    context "when sprint is active" do
      let(:sprint_status) { "active" }

      it_behaves_like "contract is invalid", status: :must_be_in_planning
    end

    context "when sprint is completed" do
      let(:sprint_status) { "completed" }

      it_behaves_like "contract is invalid", status: :must_be_in_planning
    end

    context "when the sprint has no start date" do
      let(:sprint) { create(:sprint, project:, status: sprint_status, start_date: nil) }

      it_behaves_like "contract is invalid", base: :dates_required
    end

    context "when the sprint has no finish date" do
      let(:sprint) { create(:sprint, project:, status: sprint_status, finish_date: nil) }

      it_behaves_like "contract is invalid", base: :dates_required
    end

    context "when another active sprint exists in the project" do
      before do
        create(:sprint, project:, status: "active")
      end

      it_behaves_like "contract is invalid", status: :only_one_active_sprint_allowed

      context "when the project allows multiple active sprints" do
        before { project.update!(allow_multiple_active_sprints: true) }

        it_behaves_like "contract is valid"
      end
    end

    context "when an active sprint exists in a different, unrelated project" do
      before do
        create(:sprint, project: create(:project), status: "active")
      end

      it_behaves_like "contract is valid"
    end

    context "when an active sprint is shared into the project from a share_subprojects ancestor" do
      let(:parent) { create(:project, sprint_sharing: "share_subprojects") }
      let(:project) { create(:project, parent:, sprint_sharing: "receive_shared") }

      before do
        create(:sprint, project: parent, status: "active")
      end

      it_behaves_like "contract is invalid",
                      status: %i[only_one_active_sprint_allowed cannot_start_while_receiving_shared_sprints]

      context "when the project allows multiple active sprints" do
        before { project.update!(allow_multiple_active_sprints: true) }

        it_behaves_like "contract is invalid", status: :cannot_start_while_receiving_shared_sprints
      end
    end

    context "when the project is receiving shared sprints" do
      let(:parent) { create(:project, sprint_sharing: "share_subprojects") }
      let(:project) { create(:project, parent:, sprint_sharing: "receive_shared") }

      it_behaves_like "contract is invalid", status: :cannot_start_while_receiving_shared_sprints

      context "when the project allows multiple active sprints" do
        before { project.update!(allow_multiple_active_sprints: true) }

        it_behaves_like "contract is invalid", status: :cannot_start_while_receiving_shared_sprints
      end
    end
  end
end
