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
  class SaveCopyService
    def initialize(user:, document:)
      @user = user
      @document = document
    end

    def call(journal:)
      attrs = {
        title: "#{journal.data.title} (copy)",
        description: journal.data.description,
        project: @document.project,
        type_id: journal.data.type_id,
        kind: @document.kind
      }
      attrs[:content_binary] = journal.data.content_binary if @document.collaborative?

      result = Documents::CreateService
        .new(user: @user)
        .call(attrs)

      copy_attachments(result.result) if result.success?

      result
    end

    private

    def copy_attachments(new_document)
      @document.attachments.each do |source|
        copy = source.copy
        copy.container = new_document
        copy.author = @user
        copy.save!
      rescue StandardError => e
        Rails.logger.error("Failed to copy attachment #{source.id} to document #{new_document.id}: #{e.message}")
      end
    end
  end
end
