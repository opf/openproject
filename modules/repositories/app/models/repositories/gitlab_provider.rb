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

module Repositories
  class GitlabProvider < Provider
    store_attribute :options, :url, :string
    store_attribute :options, :gitlab_user_id, :integer
    store_attribute :options, :webhook_secret, :string

    class << self
      def registry_prefix = "gitlab"
      def icon = :"op-logo-gitlab"
      def generate_webhook_secret = SecureRandom.hex(32)

      def for_web_url(url)
        all.find { UrlTools.same_base_path?(base: it.url, url: url) }
      end
    end

    # The webhook user is optional. Storing the key even for a blank user records that an admin chose
    # not to restrict the user, which the setup wizard uses to tell a skipped step from a pending one.
    def gitlab_user_id=(value)
      super
      options["gitlab_user_id"] = gitlab_user_id
    end

    def webhook_user_configured? = options.key?("gitlab_user_id")

    def webhook_user
      ::User.find_by(id: gitlab_user_id) if gitlab_user_id
    end
  end
end
