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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Repositories
  module GitlabProviders
    class BaseContract < ::BaseContract
      include RequiresAdminGuard

      attribute :name
      attribute :url
      attribute :gitlab_user_id
      attribute :webhook_secret

      validates :url, presence: true, length: { maximum: 255 }
      validates :url, url: true, unless: -> { url.blank? || errors.include?(:url) }
      validate :url_unique, unless: -> { url.blank? || errors.include?(:url) }
      validate :webhook_user_exists, if: -> { gitlab_user_id.present? }

      private

      def url_unique
        normalized = normalize_url(url)
        return if Repositories::GitlabProvider.where.not(id: model.id).none? { normalize_url(it.url) == normalized }

        errors.add(:url, :taken)
      end

      def normalize_url(value) = value.to_s.chomp("/").downcase

      def webhook_user_exists
        return if ::User.exists?(id: gitlab_user_id)

        errors.add(:gitlab_user_id, :does_not_exist)
      end
    end
  end
end
