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
  module OutboundEmails
    class ReplyAvailability
      def initialize(work_package:, user:)
        @work_package = work_package
        @user = user
      end

      def available?
        helpdesk_enabled? && user_allowed? && email_thread? && outgoing_mailbox?
      end

      private

      attr_reader :work_package, :user

      delegate :project, to: :work_package

      def helpdesk_enabled?
        OpenProject::FeatureDecisions.helpdesk_active? && project.module_enabled?(:helpdesk)
      end

      def user_allowed?
        user.allowed_in_work_package?(:add_work_package_comments, work_package)
      end

      def email_thread?
        EmailThread.exists?(work_package:)
      end

      def outgoing_mailbox?
        project.helpdesk_outgoing_mailboxes.exists?
      end
    end
  end
end
