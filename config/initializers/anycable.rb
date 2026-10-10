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

Rails.application.configure do
  # anycable-go verifies Turbo's signed stream names with the same secret (--turbo_streams).
  config.turbo.signed_stream_verifier_key = AnyCable.config.secret.presence

  # Without a secret the HTTP RPC endpoint would accept unauthenticated calls.
  if AnyCable.config.secret.blank?
    AnyCable.config.http_rpc = false
    AnyCable.config.http_rpc_mount_path = nil
  end

  if Rails.env.development?
    config.middleware.insert_before 0, OpenProject::Dev::CableTunnel
  end
end
