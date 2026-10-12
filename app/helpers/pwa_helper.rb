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

module PwaHelper
  SHORT_NAME_MAX_LENGTH = 12
  CACHE_PREFIX = "openproject-offline-"
  OFFLINE_WORDMARK = Rails.root.join("app/assets/images/logo_openproject_white_big.png")

  def pwa_short_name(title = Setting.app_title)
    [title, title.split.first].compact.find { it.length <= SHORT_NAME_MAX_LENGTH }
  end

  def pwa_cache_prefix = CACHE_PREFIX

  def pwa_cache_name
    version = [pwa_offline_path, Setting.app_title, OpenProject::VERSION.to_s].join
    "#{CACHE_PREFIX}#{Digest::SHA256.hexdigest(version).first(16)}"
  end

  def pwa_offline_wordmark_data_uri
    "data:image/png;base64,#{Base64.strict_encode64(OFFLINE_WORDMARK.binread)}"
  end
end
