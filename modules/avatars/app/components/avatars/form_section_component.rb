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

module Avatars
  class FormSectionComponent < ApplicationComponent
    def initialize(user:, target_avatar_path:)
      super()
      @user = user
      @target_avatar_path = target_avatar_path
    end

    def render?
      manager.avatars_enabled?
    end

    def description
      parts = []
      if manager.gravatar_enabled?
        gravatar_link = link_to("gravatar.com", "https://gravatar.com")
        parts << t("avatars.text_avatar_gravatar_html", gravatar_url: gravatar_link)
      end
      if manager.local_avatars_enabled?
        parts << (manager.gravatar_enabled? ? t("avatars.text_avatar_local") : t("avatars.text_avatar_local_only"))
      end
      helpers.safe_join(parts, " ")
    end

    private

    def manager
      ::OpenProject::Avatars::AvatarManager
    end
  end
end
