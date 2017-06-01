#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++
require "active_support/core_ext/module/attribute_accessors"

class UserSession < ActiveRecord::SessionStore::Session
  belongs_to :user

  ##
  # Keep an index on the current user for the given session hash
  before_save :set_user_id

  ##
  # Delete related sessions when an active session is destroyed
  after_destroy :delete_user_sessions

  private

  def set_user_id
    write_attribute(:user_id, data['user_id'])
  end

  def delete_user_sessions
    user_id = data['user_id']
    return unless user_id && OpenProject::Configuration.drop_old_sessions_on_logout?

    ::UserSession.where(user_id: user_id).delete_all
  end
end
