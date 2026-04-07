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

module CrowdinInContextHelper
  JIPT_CDN_HOST = "https://cdn.crowdin.com"

  def crowdin_in_context_active?
    Setting.crowdin_in_context_translations? &&
      ::I18n.locale == Redmine::I18n::IN_CONTEXT_TRANSLATION_CODE
  end

  # Renders the JIPT configuration inline script and the external loader script.
  #
  # The inline config script carries the CSP nonce (required because script-src
  # uses nonces). The external jipt.js is allowed by domain — cdn.crowdin.com is
  # added to script-src dynamically in ApplicationController when in-context mode
  # is active.
  def crowdin_in_context_script_tags
    return unless crowdin_in_context_active?

    config_tag = content_tag(:script, nonce: content_security_policy_nonce) do
      # rubocop:disable Rails/OutputSafety
      "var _jipt = []; _jipt.push(['project', 'openproject']);".html_safe
      # rubocop:enable Rails/OutputSafety
    end

    loader_tag = tag.script(src: "#{JIPT_CDN_HOST}/jipt/jipt.js")

    safe_join([config_tag, loader_tag])
  end
end
