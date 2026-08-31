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

RSpec.describe Backlogs::Sprints::FinishContract do
  include_context "ModelContract shared context"

  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }
  let(:sprint) { build_stubbed(:sprint, project:, status: sprint_status) }
  let(:sprint_status) { "active" }
  let(:unfinished_count) { 0 }
  let(:permissions) { [:start_complete_sprint] }

  subject(:contract) { described_class.new(sprint, user) }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project(*permissions, project:)
    end

    allow(sprint)
      .to receive_message_chain(:work_packages, :without_status_considered_closed, :count) # rubocop:disable RSpec/MessageChain
            .and_return(unfinished_count)
  end

  describe "validation" do
    context "with an active sprint, permission, and no unfinished work packages" do
      it_behaves_like "contract is valid"
    end

    context "when the sprint is not active" do
      let(:sprint_status) { "in_planning" }

      it_behaves_like "contract is invalid", status: :not_active
    end

    context "when the sprint is completed" do
      let(:sprint_status) { "completed" }

      it_behaves_like "contract is invalid", status: :not_active
    end

    context "when the user does not have start_complete_sprint permission" do
      let(:permissions) { [:view_work_packages] }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when the user has no permissions in the project" do
      let(:permissions) { [] }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when the sprint has unfinished work packages" do
      let(:unfinished_count) { 3 }

      it_behaves_like "contract is invalid", base: :unfinished_work_packages
    end

    context "when the user is an admin without explicit project permission" do
      let(:user) { build_stubbed(:admin) }
      let(:permissions) { [] }

      it_behaves_like "contract is valid"
    end
  end
end
