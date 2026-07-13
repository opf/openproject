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
require_relative "../../support/pages/meetings/show"

RSpec.describe "Series template participant management",
               :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings] })
  end
  shared_let(:participant_a) do
    create(:user, member_with_permissions: { project => %i[view_meetings] })
  end
  shared_let(:participant_b) do
    create(:user, member_with_permissions: { project => %i[view_meetings] })
  end

  let(:recurring_meeting) { create(:recurring_meeting, project:, author: user) }
  let(:template) { recurring_meeting.template }
  let(:template_page) { Pages::Meetings::Show.new(template) }

  before do
    login_as user
    template_page.visit!
  end

  describe "'apply to upcoming' checkbox state" do
    context "when adding multiple participants with checkbox unchecked" do
      it "keeps the checkbox unchecked after each addition" do
        template_page.open_participant_form
        template_page.in_participant_form do
          template_page.uncheck_apply_to_upcoming
          template_page.expect_apply_to_upcoming_unchecked

          wait_for_turbo_stream do
            template_page.select_participant(participant_a)
          end
          template_page.expect_apply_to_upcoming_unchecked

          wait_for_turbo_stream do
            template_page.select_participant(participant_b)
          end
          template_page.expect_apply_to_upcoming_unchecked
        end
      end

      it "does not add participants to occurrences" do
        open_scheduled = create(:recurring_meeting_occurrence, recurring_meeting:, start_time: 1.day.from_now)

        template_page.open_participant_form
        template_page.in_participant_form do
          template_page.uncheck_apply_to_upcoming
          template_page.expect_apply_to_upcoming_unchecked

          wait_for_turbo_stream do
            template_page.select_participant(participant_a)
          end
          wait_for_turbo_stream do
            template_page.select_participant(participant_b)
          end
        end

        expect(open_scheduled.participants.pluck(:user_id))
          .not_to include(participant_a.id, participant_b.id)
      end
    end

    context "when removing multiple participants with checkbox unchecked" do
      let!(:meeting_participant_a) do
        create(:meeting_participant, meeting: template, user: participant_a, invited: true)
      end
      let!(:meeting_participant_b) do
        create(:meeting_participant, meeting: template, user: participant_b, invited: true)
      end

      it "keeps the checkbox unchecked after each removal" do
        template_page.open_participant_form
        template_page.in_participant_form do
          template_page.uncheck_apply_to_upcoming
          template_page.expect_apply_to_upcoming_unchecked

          wait_for_turbo_stream do
            template_page.remove_participant(participant_a)
          end
          template_page.expect_apply_to_upcoming_unchecked

          wait_for_turbo_stream do
            template_page.remove_participant(participant_b)
          end
          template_page.expect_apply_to_upcoming_unchecked
        end
      end

      it "does not remove participants from occurrences" do
        open_scheduled = create(:recurring_meeting_occurrence, recurring_meeting:, start_time: 1.day.from_now)
        create(:meeting_participant, meeting: open_scheduled, user: participant_a, invited: true)
        create(:meeting_participant, meeting: open_scheduled, user: participant_b, invited: true)

        template_page.open_participant_form
        template_page.in_participant_form do
          template_page.uncheck_apply_to_upcoming
          template_page.expect_apply_to_upcoming_unchecked

          wait_for_turbo_stream do
            template_page.remove_participant(participant_a)
          end
          wait_for_turbo_stream do
            template_page.remove_participant(participant_b)
          end
        end

        expect(open_scheduled.participants.reload.pluck(:user_id))
          .to include(participant_a.id, participant_b.id)
      end
    end

    it "defaults to checked when the dialog is reopened" do
      template_page.open_participant_form
      template_page.in_participant_form do
        template_page.uncheck_apply_to_upcoming
        template_page.expect_apply_to_upcoming_unchecked
        page.find(".close-button").click
      end

      template_page.open_participant_form
      template_page.in_participant_form do
        template_page.expect_apply_to_upcoming_checked
      end
    end
  end
end
