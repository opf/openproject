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

RSpec.shared_context "with a mentioned work package being updated again" do
  let(:project) { create(:project) }

  let(:work_package) do
    create(:work_package, project:).tap do |wp|
      # Clear the initial journal job
      wp.save!
      clear_enqueued_jobs
    end
  end

  let(:role) do
    create(:project_role, permissions: %w[view_work_packages edit_work_packages])
  end

  let(:recipient) do
    create(:user,
           preferences: {
             immediate_reminders: {
               mentioned: true
             }
           },
           notification_settings: [
             build(:notification_setting,
                   mentioned: true,
                   assignee: true,
                   responsible: true)
           ],
           member_with_roles: { project => role })
  end
  let(:actor) do
    create(:user, member_with_roles: { project => role })
  end

  let(:comment) do
    <<~NOTE
      Hello <mention class="mention" data-type="user" data-id="#{recipient.id}" data-text="@#{recipient.name}">@#{recipient.name}</mention>
    NOTE
  end

  let(:mentioned_notification) do
    Notification.find_by(recipient:, journal: work_package.journals.last, reason: :mentioned)
  end

  def trigger_comment!
    User.execute_as(actor) do
      work_package.journal_notes = comment
      work_package.save!
    end

    perform_enqueued_jobs
    work_package.reload
  end

  def update_assignee!(assignee_user = recipient)
    clear_enqueued_jobs

    User.execute_as(actor) do
      work_package.assigned_to = assignee_user
      work_package.save!
    end

    perform_enqueued_jobs
    work_package.reload
  end
end
