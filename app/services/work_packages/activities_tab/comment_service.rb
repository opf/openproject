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

module WorkPackages
  module ActivitiesTab
    # Builds and runs the service behind a comment write, resolving the note body
    # (mentions are sanitised only for internal comments) and coercing the request
    # flags. Callers handle the returned ServiceResult; this owns how a comment is
    # written.
    class CommentService
      def initialize(work_package:, user:, params:)
        @work_package = work_package
        @user = user
        @params = params
      end

      def add
        AddWorkPackageNoteService
          .new(user:, work_package:)
          .call(note_body(internal:), send_notifications:, internal:)
      end

      def update(journal)
        ::Journals::UpdateService
          .new(model: journal, user:)
          .call(notes: note_body(internal: journal.internal?))
      end

      def sanitized_notes
        InternalCommentMentionsSanitizer.sanitize(work_package, journal_params[:notes])
      end

      private

      attr_reader :work_package, :user, :params

      def note_body(internal:)
        internal ? sanitized_notes : journal_params[:notes]
      end

      def internal
        to_boolean(journal_params[:internal], false)
      end

      def send_notifications
        to_boolean(params[:notify], true)
      end

      def journal_params
        params.expect(journal: %i[notes internal])
      end

      def to_boolean(value, default)
        ActiveRecord::Type::Boolean.new.cast(value.presence || default)
      end
    end
  end
end
