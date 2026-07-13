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

RSpec.describe MeetingAgendaItems::DropService do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] }) }

  describe "#call" do
    context "when the meeting is present" do
      let(:meeting) { create(:meeting, project: project) }
      let!(:section_one) { create(:meeting_section, meeting: meeting) }
      let!(:section_two) { create(:meeting_section, meeting: meeting) }
      let!(:first_item) { create(:meeting_agenda_item, meeting: meeting, meeting_section: section_one) }
      let!(:meeting_agenda_item) { create(:meeting_agenda_item, meeting: meeting, meeting_section: section_one) }
      let(:target_id) { section_two.id }
      let(:position) { 1 }

      subject(:service_call) do
        described_class
          .new(user: user, meeting_agenda_item: meeting_agenda_item)
          .call(target_id: target_id, position: position)
      end

      context "when moving the item to another section" do
        it "moves the agenda item and returns the section change details" do
          expect(service_call).to be_success

          meeting_agenda_item.reload
          expect(meeting_agenda_item.meeting_section).to eq(section_two)
          expect(meeting_agenda_item.position).to eq(1)
          expect(service_call.result).to include(
            section_changed: true,
            current_section: section_two,
            old_section: section_one
          )
        end
      end

      context "when moving the item within the same section" do
        let(:target_id) { section_one.id }

        it "updates the position without changing the section" do
          expect(service_call).to be_success

          meeting_agenda_item.reload
          expect(meeting_agenda_item.meeting_section).to eq(section_one)
          expect(meeting_agenda_item.position).to eq(1)
          expect(first_item.reload.position).to eq(2)
          expect(service_call.result).to include(
            section_changed: false,
            current_section: section_one,
            old_section: nil
          )
        end
      end

      context "when moving the item to a section from another meeting" do
        let(:other_meeting) { create(:meeting, project: project) }
        let(:target_id) { create(:meeting_section, meeting: other_meeting).id }

        it "fails without changing the agenda item" do
          expect do
            service_call
            meeting_agenda_item.reload
          end.not_to change { meeting_agenda_item }

          expect(service_call).to be_failure
          expect(service_call.errors[:base].join).to match(/Couldn't find MeetingSection/)
        end
      end

      context "when the user lacks permission" do
        let(:user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }

        it "fails without changing the agenda item" do
          expect do
            service_call
            meeting_agenda_item.reload
          end.not_to change { meeting_agenda_item }

          expect(service_call).to be_failure
        end
      end

      context "when the agenda item is not editable" do
        let(:meeting) { create(:meeting, project: project, state: :closed) }

        it "fails without changing the agenda item" do
          expect do
            service_call
            meeting_agenda_item.reload
          end.not_to change { meeting_agenda_item }

          expect(service_call).to be_failure
        end
      end
    end

    context "when the agenda item is in the recurring meeting template backlog" do
      let(:recurring_meeting) { create(:recurring_meeting, project: project) }
      let(:template) { recurring_meeting.template }
      let(:meeting_agenda_item) do
        create(:meeting_agenda_item, meeting: template, meeting_section: template.backlog)
      end
      let(:position) { 1 }

      subject(:service_call) do
        described_class
          .new(user: user, meeting_agenda_item: meeting_agenda_item)
          .call(target_id: target_id, position: position)
      end

      context "when moving to a section from another meeting in the same series" do
        let(:occurrence_meeting) { create(:recurring_meeting_occurrence, project:, recurring_meeting:) }
        let(:target_section) { create(:meeting_section, meeting: occurrence_meeting) }
        let(:target_id) { target_section.id }

        it "moves the item to the target meeting section" do
          expect(service_call).to be_success

          meeting_agenda_item.reload
          expect(meeting_agenda_item.meeting_section).to eq(target_section)
          expect(meeting_agenda_item.meeting).to eq(occurrence_meeting)
        end
      end

      context "when moving to a section from another recurring meeting" do
        let(:other_recurring_meeting) { create(:recurring_meeting, project: project) }
        let(:target_id) { create(:meeting_section, meeting: other_recurring_meeting.template).id }

        it "fails without changing the agenda item" do
          expect { service_call }.not_to change { meeting_agenda_item.reload.meeting_section_id }

          expect(service_call).to be_failure
          expect(service_call.errors[:base].join).to match(/Couldn't find MeetingSection/)
        end
      end

      context "when moving to a non-existent section" do
        let(:target_id) { MeetingSection.maximum(:id).to_i + 1 }

        it "fails without changing the agenda item" do
          expect { service_call }.not_to change { meeting_agenda_item.reload.meeting_section_id }

          expect(service_call).to be_failure
          expect(service_call.errors[:base].join).to match(/Couldn't find MeetingSection/)
        end
      end
    end

    context "when moving an agenda item from a recurring meeting to a backlog" do
      let(:recurring_meeting) { create(:recurring_meeting, project: project) }
      let(:template) { recurring_meeting.template }
      let(:occurrence_meeting) { create(:recurring_meeting_occurrence, project: project, recurring_meeting: recurring_meeting) }
      let(:meeting_section) { create(:meeting_section, meeting: occurrence_meeting) }
      let(:meeting_agenda_item) do
        create(:meeting_agenda_item, meeting: occurrence_meeting, meeting_section: meeting_section)
      end
      let(:position) { 1 }

      subject(:service_call) do
        described_class
          .new(user: user, meeting_agenda_item: meeting_agenda_item)
          .call(target_id: target_id, position: position)
      end

      context "when moving to the backlog of the recurring meeting" do
        let(:target_id) { occurrence_meeting.backlog.id }

        it "moves the item to the template backlog" do
          expect(service_call).to be_success

          meeting_agenda_item.reload
          expect(meeting_agenda_item.meeting_section).to eq(template.backlog)
          expect(meeting_agenda_item.meeting).to eq(template)
        end
      end

      context "when moving to the backlog of another recurring meeting" do
        let(:other_recurring_meeting) { create(:recurring_meeting, project: project) }
        let(:target_id) { other_recurring_meeting.template.backlog.id }

        it "fails without changing the agenda item" do
          result = nil

          expect { result = service_call }
            .not_to change { meeting_agenda_item.reload.meeting_section_id }

          expect(result).to be_failure
          expect(result.errors[:base].join).to match(/Couldn't find MeetingSection/)
        end
      end
    end

    context "when the meeting is missing" do
      let(:meeting) { instance_double(Meeting, project: project, present?: false) }
      let(:section) { instance_double(MeetingSection, id: 1) }
      let(:meeting_agenda_item) do
        instance_double(MeetingAgendaItem, meeting_section: section, meeting: meeting, editable?: true)
      end

      subject(:service_call) do
        described_class
          .new(user: user, meeting_agenda_item: meeting_agenda_item)
          .call(target_id: 1, position: 1)
      end

      it "fails before attempting to drop the item" do
        expect(service_call).to be_failure
      end
    end
  end
end
