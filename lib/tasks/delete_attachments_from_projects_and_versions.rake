#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'shared/user_feedback'

namespace :migrations do
  namespace :attachments do
    include ::Tasks::Shared::UserFeedback

    desc 'Removes all attachments from versions and projects'
    task delete_from_projects_and_versions: :environment do |_task|
      try_delete_attachments_from_projects_and_versions
    end

    def try_delete_attachments_from_projects_and_versions
      if !$stdout.isatty || user_agrees_to_delete_versions_and_projects_documents
        puts 'Delete all attachments attached to projects or versions...'

        Attachment.where(container_type: ['Version', 'Project']).destroy_all
      end
    rescue
      raise 'Cannot delete attachments from projects and versions! There may be migrations missing...?'
    end

    def user_agrees_to_delete_versions_and_projects_documents
      questions = ['CAUTION: This rake task will delete ALL attachments attached to versions or projects!',
                   "DISCLAIMER: This is the final warning: You're going to lose information!"]

      ask_for_confirmation(questions)
    end
  end
end
