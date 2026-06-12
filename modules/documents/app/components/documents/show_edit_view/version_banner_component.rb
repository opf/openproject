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
  module ShowEditView
    class VersionBannerComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      alias_method :document, :model

      options :version_journal, :project

      def author
        version_journal.user
      end

      def created_at
        version_journal.created_at
      end

      def can_manage?
        User.current.allowed_in_project?(:manage_documents, project)
      end

      def restore_path
        restore_version_document_path(document, version_id: version_journal.id)
      end

      def save_copy_path
        save_copy_document_path(document, version_id: version_journal.id)
      end
    end
  end
end
