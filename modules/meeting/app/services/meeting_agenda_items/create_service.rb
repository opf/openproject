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

module MeetingAgendaItems
  class CreateService < ::BaseServices::Create
    include AfterPerformHook
    include Concerns::CopyAttachments

    alias_method :original_after_perform, :after_perform

    def call(params)
      @source_meeting_id = params.delete(:source_meeting_id)
      super
    end

    def after_perform(call)
      # The reload is required because, the time slot calculations are changing the
      # `start_time`, `end_time` attributes and they should be available for rendering.
      call.result.reload
      original_after_perform(call)

      copy_attachments_from_source(call.result) if call.success?

      call
    end

    private

    def copy_attachments_from_source(agenda_item)
      copy_attachments_from_meeting(agenda_item, @source_meeting_id) if @source_meeting_id.present?
    end
  end
end
