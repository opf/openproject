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

RSpec.describe RecurringMeetings::ResetToTemplateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  let(:recurring_meeting) { create(:recurring_meeting, project:) }
  let(:meeting) do
    create(:meeting,
           project:,
           recurring_meeting:,
           start_time: recurring_meeting.start_time + 1.day,
           recurrence_start_time: recurring_meeting.start_time + 1.day,
           state: :cancelled)
  end
  let(:contract_options) { {} }
  let(:contract) { described_class.new(meeting, user, options: contract_options) }

  context "when reopening a cancelled occurrence" do
    let(:contract_options) { { reopening: true } }

    context "with create_meetings permission" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_meetings create_meetings] })
      end

      it_behaves_like "contract is valid"
    end

    context "with only edit_meetings permission" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] })
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "with only view_meetings permission" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_meetings] })
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "when the occurrence project differs from the series project" do
      let(:other_project) { create(:project, enabled_module_names: %i[meetings]) }
      let(:meeting) do
        create(:meeting,
               project: other_project,
               recurring_meeting:,
               start_time: recurring_meeting.start_time + 1.day,
               recurrence_start_time: recurring_meeting.start_time + 1.day,
               state: :cancelled)
      end
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_meetings create_meetings] })
      end

      it_behaves_like "contract is valid"
    end
  end

  context "when resetting content without reopening" do
    let(:contract_options) { { reopening: false } }

    context "with edit_meetings permission" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] })
      end

      it_behaves_like "contract is valid"
    end

    context "with only create_meetings permission" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_meetings create_meetings] })
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end

    context "with only view_meetings permission" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_meetings] })
      end

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end
end
