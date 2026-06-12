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

module Documents
  class RestoreVersionService
    def initialize(user:, document:)
      @user = user
      @document = document
    end

    def call(journal:)
      attrs = {
        title: journal.data.title,
        description: journal.data.description
      }
      attrs[:type_id] = journal.data.type_id if journal.data.type_id.present?
      attrs[:content_binary] = journal.data.content_binary if @document.collaborative?

      # Prevent aggregation so restore always appends a new journal entry.
      @document.skip_journal_aggregation = true
      @document.journal_cause = CauseOfChange::Base.new("document_version_restored",
                                                         "restored_journal_id" => journal.id)

      Documents::UpdateService
        .new(user: @user, model: @document)
        .call(attrs)
    end
  end
end
