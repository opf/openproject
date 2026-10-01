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
  class BaseContract < ::ModelContract
    include Attachments::ValidateReplacements
    include UnchangedProject

    def self.model
      Document
    end

    attribute :project
    attribute :type
    attribute :kind
    attribute :title
    attribute :description
    attribute :content_binary

    validate :validate_manage_allowed_in_source_project
    validate :validate_manage_allowed_in_destination_project

    private

    def validate_manage_allowed_in_source_project
      if model.new_record?
        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_documents, model.project)
        return
      end

      with_unchanged_project_id do
        errors.add :base, :error_unauthorized unless user.allowed_in_project?(:manage_documents, model.project)
      end
    end

    def validate_manage_allowed_in_destination_project
      return if model.new_record?
      return unless model.project_id_changed?

      unless user.allowed_in_project?(:manage_documents, model.project)
        errors.add :base, :error_unauthorized
      end
    end
  end
end
