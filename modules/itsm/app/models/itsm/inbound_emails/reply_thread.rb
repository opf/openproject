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

module ITSM
  module InboundEmails
    class ReplyThread
      SUBJECT_ID = /\[(?:#(\d+)|(#{WorkPackage::SemanticIdentifier::SEMANTIC_ID_PATTERN.source}))\]/

      def self.find(email, project) = new(email, project).find

      def initialize(email, project)
        @headers = email.headers
        @project = project
      end

      def find = by_headers || by_subject

      private

      attr_reader :headers, :project

      # Matching in both directions also finds the request when a reply was processed before the email it answers.
      def by_headers
        messages = EmailMessage.in_project(project)

        messages.where(message_id: [headers.in_reply_to, *headers.references].compact)
          .or(messages.referring_to(headers.message_id))
          .order(:id)
          .first
          &.thread
      end

      def by_subject
        work_package = subject_work_package
        return if work_package.nil?

        EmailThread.in_project(project).with_participant(headers.from_address).find_by(work_package:)
      end

      def subject_work_package
        reference = SUBJECT_ID.match(headers.subject.to_s)&.then { it[1] || it[2] }
        WorkPackage.where(project:).find_by_display_id(reference) if reference
      end
    end
  end
end
