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

module Wikis
  module RelationPageLinks
    class CreateContract < ::ModelContract
      attribute :author
      attribute :identifier
      attribute :linkable_type
      attribute :linkable_id
      attribute :provider
      attribute :type

      validates :identifier, presence: true
      validates :linkable_type, presence: true
      validates :linkable_id, presence: true
      validates :provider, presence: true
      validates :type, inclusion: { in: [RelationPageLink.name] }

      validate :provider_exists?
      validate :author_must_be_user
      validate :validate_user_allowed_to_manage

      private

      def author_must_be_user
        return if user.admin? && Setting.apiv3_write_readonly_attributes?

        errors.add(:author, :invalid) unless author == user
      end

      def validate_user_allowed_to_manage
        linkable = model.linkable

        if linkable.present? && !user.allowed_in_project?(:manage_wiki_page_links, linkable.project)
          errors.add(:base, :error_unauthorized)
        end
      end

      def provider_exists?
        errors.add(:provider, :does_not_exist) if model.provider.is_a?(InexistentProvider)
      end
    end
  end
end
