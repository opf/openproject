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

RSpec.describe RecurringMeetings::UpdateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project) }
  shared_let(:meeting) { create(:recurring_meeting, project:) }
  let(:contract) { described_class.new(meeting, user) }

  context "with permission" do
    let(:user) do
      create(:user, member_with_permissions: { project => [:edit_meetings] })
    end

    it_behaves_like "contract is valid"
  end

  context "without permission" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  context "when moving to another project" do
    let(:target_project) { create(:project) }

    before do
      meeting.project_id = target_project.id
      meeting.title = "Moved Recurring Meeting Title"
    end

    context "when only authorized in target project" do
      let(:user) do
        create(:user, member_with_permissions: { target_project => [:edit_meetings] })
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when only authorized in source project" do
      let(:user) do
        create(:user, member_with_permissions: { project => [:edit_meetings] })
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when authorized in both projects" do
      let(:user) do
        create(:user,
               member_with_permissions: {
                 project => [:edit_meetings],
                 target_project => [:edit_meetings]
               })
      end

      it_behaves_like "contract is valid"
    end
  end

  include_examples "contract reuses the model errors" do
    let(:user) { build_stubbed(:user) }
  end
end
