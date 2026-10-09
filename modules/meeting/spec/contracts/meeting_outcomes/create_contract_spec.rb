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

RSpec.describe MeetingOutcomes::CreateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project) }
  let(:meeting) { create(:meeting, project:) }
  let(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:) }
  let(:outcome) { build(:meeting_outcome, meeting_agenda_item:) }
  let(:contract) { described_class.new(outcome, user) }

  context "with permission" do
    let(:user) do
      create(:user, member_with_permissions: { project => %i[view_meetings manage_outcomes] })
    end

    context "when :meeting is 'in_progress'" do
      before do
        meeting.update_column(:state, :in_progress)
      end

      it_behaves_like "contract is valid"
    end

    context "when :meeting is 'open'" do
      before do
        meeting.update_column(:state, :open)
      end

      it_behaves_like "contract is invalid", base: I18n.t(:text_outcome_not_editable_anymore)
    end

    context "when :meeting is 'closed'" do
      before do
        meeting.update_column(:state, :closed)
      end

      it_behaves_like "contract is invalid", base: I18n.t(:text_outcome_not_editable_anymore)
    end

    context "when :meeting_agenda_item is not present anymore" do
      before do
        meeting_agenda_item.destroy
      end

      it_behaves_like "contract is invalid", base: I18n.t(:text_outcome_not_editable_anymore)
    end

    context "when :meeting_agenda_item is in a backlog" do
      before do
        meeting.update_column(:state, :in_progress)
        meeting_agenda_item.meeting_section.update_column(:backlog, true)
      end

      it_behaves_like "contract is invalid", base: I18n.t(:text_outcome_not_editable_anymore)
    end

    context "when work_package_id is set" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[view_meetings manage_outcomes view_work_packages] })
      end
      let(:other_project) { create(:project) }
      let(:work_package) { create(:work_package, project:) }
      let(:other_work_package) { create(:work_package, project: other_project) }
      let(:outcome) { build(:meeting_outcome, meeting_agenda_item:, work_package:, kind: :work_package) }

      before do
        meeting.update_column(:state, :in_progress)
      end

      context "when user can view the work package" do
        it_behaves_like "contract is valid"
      end

      context "when user cannot view the work package" do
        let(:outcome) { build(:meeting_outcome, meeting_agenda_item:, work_package: other_work_package, kind: :work_package) }

        it_behaves_like "contract is invalid", work_package: :error_not_found
      end

      context "when the referenced work package doesn't exist" do
        let(:outcome) { build(:meeting_outcome, meeting_agenda_item:, work_package: nil, kind: :work_package) }

        before do
          outcome.work_package_id = 999999
        end

        it_behaves_like "contract is invalid", work_package: %i[blank error_not_found]
      end
    end
  end

  context "without permission" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :does_not_exist
  end

  include_examples "contract reuses the model errors" do
    let(:user) { build_stubbed(:user) }
  end
end
