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
require "contracts/shared/model_contract_shared_context"

RSpec.describe ProjectPhases::UpdateStatusContract do
  include_context "ModelContract shared context"

  let(:user) { build_stubbed(:user) }
  let(:phase) { build_stubbed(:project_phase) }
  let(:project) { phase.project }

  subject(:contract) { described_class.new(phase, user) }

  context "with authorized user" do
    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:edit_project_phases, project:)
      end
    end

    describe "contract validations" do
      it_behaves_like "contract is valid"
      it_behaves_like "contract reuses the model errors"

      Project::Phase.statuses.each_key do |status|
        context "when changing the status to #{status}" do
          before { phase.status = status }

          it_behaves_like "contract is valid"
        end
      end

      context "when changing the status to an unknown value" do
        before { phase.status = "bogus" }

        it_behaves_like "contract is invalid", status: :inclusion
      end

      context "when trying to change attributes other than the status" do
        {
          start_date: Date.current - 3,
          finish_date: Date.current + 3,
          active: false,
          duration: 42
        }.each do |attribute, value|
          context "with #{attribute}" do
            before { phase.public_send(:"#{attribute}=", value) }

            it_behaves_like "contract is invalid", attribute => :error_readonly
          end
        end

        context "when also changing the status" do
          before do
            phase.status = "completed"
            phase.start_date = Date.current - 3
          end

          it_behaves_like "contract is invalid", start_date: :error_readonly, status: []
        end
      end
    end
  end

  context "with unauthorized user" do
    it_behaves_like "contract user is unauthorized"

    context "when changing the status" do
      before { phase.status = "completed" }

      it_behaves_like "contract user is unauthorized"
    end

    context "when the user may only view project phases" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_project_phases, project:)
        end
      end

      it_behaves_like "contract user is unauthorized"
    end

    context "when the user may only edit the project, not its phases" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:edit_project, project:)
        end
      end

      it_behaves_like "contract user is unauthorized"
    end
  end
end
