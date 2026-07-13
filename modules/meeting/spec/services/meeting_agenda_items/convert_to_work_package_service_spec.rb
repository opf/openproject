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

RSpec.describe MeetingAgendaItems::ConvertToWorkPackageService do
  shared_let(:type) { create(:type_task) }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }

  let(:project) { create(:project, types: [type]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_meetings manage_agendas add_work_packages view_work_packages]
           })
  end
  let(:meeting) { create(:meeting, project:) }
  let(:meeting_agenda_item) do
    create(:meeting_agenda_item,
           meeting:,
           author: user,
           title: "Discuss roadmap",
           notes: "Some discussion notes")
  end

  subject(:service) { described_class.new(user:, project:) }

  describe "#build_work_package" do
    it "pre-fills subject from the agenda item title" do
      wp = service.build_work_package(meeting_agenda_item:)
      expect(wp.subject).to eq("Discuss roadmap")
    end

    it "pre-fills description from the notes" do
      wp = service.build_work_package(meeting_agenda_item:)
      expect(wp.description).to include("Some discussion notes")
    end

    it "selects an assignable type by default" do
      wp = service.build_work_package(meeting_agenda_item:)
      expect(wp.type).to be_present
    end

    context "when params override defaults" do
      it "uses provided subject over the agenda title" do
        wp = service.build_work_package(meeting_agenda_item:, params: { subject: "Custom subject" })
        expect(wp.subject).to eq("Custom subject")
      end
    end
  end

  describe "#call" do
    let(:work_package_params) do
      {
        type:,
        subject: "Converted item",
        description: "A description"
      }
    end

    context "with valid params" do
      it "creates a work package" do
        expect { service.call(meeting_agenda_item:, work_package_params:) }
          .to change(WorkPackage, :count).by(1)
      end

      it "converts the agenda item to a work_package type linking the new WP" do
        call = service.call(meeting_agenda_item:, work_package_params:)
        meeting_agenda_item.reload

        expect(call).to be_success
        expect(meeting_agenda_item).to be_work_package
        expect(meeting_agenda_item.work_package_id).to eq(call.result.id)
      end

      it "clears the title and replaces notes with a description macro" do
        call = service.call(meeting_agenda_item:, work_package_params:)
        meeting_agenda_item.reload

        expect(meeting_agenda_item.title).to be_nil
        expect(meeting_agenda_item.notes).to eq("workPackageValue:#{call.result.id}:description")
      end
    end

    context "when the work package cannot be created" do
      let(:work_package_params) { { type:, subject: nil } }

      it "fails and does not modify the agenda item" do
        expect { service.call(meeting_agenda_item:, work_package_params:) }
          .not_to change(WorkPackage, :count)

        meeting_agenda_item.reload
        expect(meeting_agenda_item).to be_simple
        expect(meeting_agenda_item.work_package_id).to be_nil
        expect(meeting_agenda_item.title).to eq("Discuss roadmap")
        expect(meeting_agenda_item.notes).to eq("Some discussion notes")
      end
    end

    context "when the agenda item update fails", :aggregate_failures do
      it "rolls back the work package creation" do
        allow_any_instance_of(MeetingAgendaItem).to receive(:save).and_return(false) # rubocop:disable RSpec/AnyInstance

        expect { service.call(meeting_agenda_item:, work_package_params:) }
          .not_to change(WorkPackage, :count)
      end
    end
  end
end
