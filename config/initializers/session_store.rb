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

# Be sure to restart your server when you modify this file.
config = OpenProject::Configuration

relative_url_root = config["rails_relative_url_root"].presence

session_options = {
  key: config["session_cookie_name"],
  httponly: true,
  secure: config.https?,
  path: relative_url_root
}

Rails.application.config.session_store :active_record_store, **session_options

Rails.application.reloader.to_prepare do
  ##
  # We use our own decorated session model to note the user_id
  # for each session.
  ActionDispatch::Session::ActiveRecordStore.session_class = Sessions::SqlBypass
  # Continue to use marshal serialization to retain symbols and whatnot
  ActiveRecord::SessionStore::Session.serializer = :marshal
end
