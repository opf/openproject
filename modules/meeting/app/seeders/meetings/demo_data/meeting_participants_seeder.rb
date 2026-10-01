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

module Meetings
  module DemoData
    # Adds the regular attendees to the weekly meeting series template. This runs *before* the
    # finalizer so every occurrence the finalizer (and the recurrence job) instantiates inherits
    # the participants. Everybody accepts by default; individual exceptions are seeded per
    # occurrence by the MeetingOccurrencesSeeder.
    class MeetingParticipantsSeeder < ::Seeder
      # The regular attendees of the weekly meeting (references to demo project members).
      BASE_ATTENDEES = %i[
        openproject_admin
        user__marko_marketing
        user__wanda_web
        user__evan_events
        user__fritz_finance
      ].freeze

      attr_reader :project

      def initialize(project, seed_data)
        super(seed_data)
        @project = project
      end

      def applicable?
        template.present?
      end

      def not_applicable_message
        "Skipping meeting participants as no meeting series template exists for project #{project.identifier}"
      end

      def seed_data!
        print_status "    ↳ Adding meeting participants" do
          BASE_ATTENDEES.each do |reference|
            user = seed_data.find_reference(reference, default: nil)
            next unless user

            # The meeting author is already a participant, so upsert rather than create.
            participant = template.participants.find_or_initialize_by(user:)
            participant.update!(invited: true, participation_status: :accepted)
          end
        end
      end

      private

      def template
        @template ||= project.recurring_meetings.first&.template
      end
    end
  end
end
