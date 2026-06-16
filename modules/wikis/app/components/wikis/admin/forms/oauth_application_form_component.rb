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

module Wikis::Admin::Forms
  class OAuthApplicationFormComponent < Wikis::Admin::WikiProviderComponent
    def self.wrapper_key = :wiki_provider_oauth_application_section

    delegate :oauth_application, to: :wiki_provider

    options in_wizard: false

    def done_button_path
      if in_wizard
        url_helpers.new_admin_settings_wiki_provider_path(continue_wizard: wiki_provider.id)
      else
        url_helpers.edit_admin_settings_wiki_provider_path(wiki_provider)
      end
    end

    def xwiki_admin_url
      Wikis::Admin::XWikiAdminUrlHelper.url(base_url: wiki_provider.url, section: "OpenProject")
    end
  end
end
