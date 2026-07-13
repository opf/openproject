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

RSpec.describe MeetingAgendaItems::UpdateContract do
  include_context "ModelContract shared context"

  shared_let(:project) { create(:project) }
  shared_let(:other_project) { create(:project) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:item) { create(:meeting_agenda_item, meeting:) }
  let(:contract) { described_class.new(item, user) }

  context "with permission" do
    let(:user) do
      create(:user, member_with_permissions: { project => [:manage_agendas] })
    end

    it_behaves_like "contract is valid"

    context "when :meeting is not editable" do
      before do
        meeting.update_column(:state, :closed)
      end

      it_behaves_like "contract is invalid", base: I18n.t(:text_agenda_item_not_editable_anymore)
    end

    context "when an item_type is provided" do
      before do
        allow(item).to receive(:changed).and_return(["item_type"])
      end

      it_behaves_like "contract is invalid", item_type: :error_readonly
    end

    context "when moving to a different meeting_section" do
      let(:new_section) { create(:meeting_section, meeting:) }

      before { item.meeting_section = new_section }

      context "when the section belongs to the same meeting" do
        it_behaves_like "contract is valid"
      end

      context "when the section belongs to an unrelated meeting" do
        let(:other_meeting) { create(:meeting, project:) }
        let(:new_section) { create(:meeting_section, meeting: other_meeting) }

        it_behaves_like "contract is invalid", meeting_section: :invalid
      end

      context "when the section belongs to a different meeting in the same series" do
        let(:recurring_meeting) { create(:recurring_meeting, project:, author: user) }
        let(:occurrence) do
          create(:recurring_meeting_occurrence, project:, recurring_meeting:, template: false)
        end
        let(:item) { create(:meeting_agenda_item, meeting: recurring_meeting.template) }
        let(:new_section) { create(:meeting_section, meeting: occurrence) }

        it_behaves_like "contract is valid"
      end

      context "when the section belongs to a meeting in a different series" do
        let(:other_recurring_meeting) { create(:recurring_meeting, project:, author: user) }
        let(:new_section) { create(:meeting_section, meeting: other_recurring_meeting.template) }
        let(:recurring_meeting) { create(:recurring_meeting, project:, author: user) }
        let(:item) { create(:meeting_agenda_item, meeting: recurring_meeting.template) }

        it_behaves_like "contract is invalid", meeting_section: :invalid
      end
    end

    context "when moving to a different meeting" do
      let(:other_meeting) { create(:meeting, project: other_project) }
      let(:other_section) { create(:meeting_section, meeting: other_meeting) }

      before do
        item.meeting = other_meeting
        item.meeting_section = other_section
      end

      context "with permission in the source and destination projects" do
        let(:user) do
          create(:user, member_with_permissions: {
                   project => [:manage_agendas],
                   other_project => [:manage_agendas]
                 })
        end

        it_behaves_like "contract is valid"
      end

      context "without permission in the source project" do
        let(:user) do
          create(:user, member_with_permissions: { other_project => [:manage_agendas] })
        end

        it_behaves_like "contract is invalid", base: :error_unauthorized
      end

      context "without permission in the destination project" do
        it_behaves_like "contract is invalid", base: :error_unauthorized
      end
    end

    context "with presenter" do
      before do
        item.presenter = presenter
      end

      context "when presenter can view meetings in the project" do
        let(:presenter) { create(:user, member_with_permissions: { project => [:view_meetings] }) }

        it_behaves_like "contract is valid"
      end

      context "when presenter cannot view meetings in the project" do
        let(:presenter) { create(:user) }

        it_behaves_like "contract is invalid", presenter: :user_invalid do
          it "does not include the presenter's name in the error message" do
            expect(contract.errors[:presenter]).not_to include(presenter.name)
          end
        end
      end
    end

    context "when changing work_package_id" do
      let(:user) do
        create(:user, member_with_permissions: { project => %i[manage_agendas view_work_packages] })
      end
      let(:other_project) { create(:project) }
      let(:visible_work_package) { create(:work_package, project:) }
      let(:other_visible_work_package) { create(:work_package, project:) }
      let(:other_work_package) { create(:work_package, project: other_project) }
      let(:item) { create(:wp_meeting_agenda_item, meeting:, work_package: visible_work_package) }

      context "when the new work package is visible" do
        before do
          item.work_package = other_visible_work_package
        end

        it_behaves_like "contract is valid"
      end

      context "when the new work package is not visible" do
        before do
          item.work_package = other_work_package
        end

        it_behaves_like "contract is invalid", work_package: :error_not_found
      end
    end
  end

  context "without permission" do
    let(:user) { build_stubbed(:user) }

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  include_examples "contract reuses the model errors" do
    let(:user) { build_stubbed(:user) }
  end
end
