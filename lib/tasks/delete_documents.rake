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

require_relative "shared/user_feedback"

namespace :migrations do
  namespace :documents do
    include Tasks::Shared::UserFeedback

    # rubocop:disable Rails/ApplicationRecord
    class TemporaryDocument < ActiveRecord::Base
      belongs_to :project
      belongs_to :category, class_name: "DocumentCategory"
    end
    # rubocop:enable Rails/ApplicationRecord

    desc "Removes all documents"
    task delete: :environment do |_task|
      try_delete_documents
    end

    def try_delete_documents
      if !$stdout.isatty || user_agrees_to_delete_all_documents
        puts "Delete all attachments attached to projects or versions..."

        TemporaryDocument.destroy_all
        Attachment.where(container_type: ["Document"]).destroy_all
      end
    rescue StandardError
      raise "Cannot delete documents! There may be migrations missing...?"
    end

    def user_agrees_to_delete_all_documents
      questions = ["CAUTION: This rake task will delete ALL documents!",
                   "DISCLAIMER: This is the final warning: You're going to lose information!"]

      ask_for_confirmation(questions)
    end
  end
end
