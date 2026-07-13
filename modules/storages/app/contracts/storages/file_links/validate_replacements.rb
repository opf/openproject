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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module FileLinks
    module ValidateReplacements
      extend ActiveSupport::Concern

      included do
        validate :user_allowed_to_manage_file_links
        validate :validate_file_links_replacements
      end

      private

      def user_allowed_to_manage_file_links
        return if model.file_links_replacements.nil?
        return if user.allowed_in_project?(:manage_file_links, model.project)

        errors.add(:base, :error_unauthorized)
      end

      def validate_file_links_replacements
        model.file_links_replacements&.each do |file_link|
          error_if_wrong_storage(file_link)
          error_if_not_allowed_to_manage(file_link)
        end
      end

      def error_if_wrong_storage(file_link)
        return if model.project.storages.include?(file_link.storage)

        errors.add :file_links, :invalid
      end

      def error_if_not_allowed_to_manage(file_link)
        return if file_link.user_allowed_to_manage?(user)

        errors.add(:base, :error_unauthorized)
      end
    end
  end
end
