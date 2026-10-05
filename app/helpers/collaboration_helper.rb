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

module CollaborationHelper
  def collaboration_provider_controller(resource_url:, token_payload:, token_expires_in_seconds:, refresh_url:)
    content_controller(
      "collaboration--init-yjs-provider",
      "collaboration--init-yjs-provider-hocuspocus-url-value": Setting.collaborative_editing_hocuspocus_url,
      "collaboration--init-yjs-provider-token-payload-value": token_payload,
      "collaboration--init-yjs-provider-document-name-value": resource_url,
      "collaboration--init-yjs-provider-token-expires-in-seconds-value": token_expires_in_seconds,
      "collaboration--init-yjs-provider-refresh-url-value": refresh_url
    )
  end
end
