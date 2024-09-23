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

class WatchersController < ApplicationController
  before_action :find_watched_by_object,
                :find_project,
                :require_login,
                :deny_access_unless_visible

  authorization_checked! :watch,
                         :unwatch

  def watch
    set_watcher(User.current, true)
  end

  def unwatch
    set_watcher(User.current, false)
  end

  private

  def find_watched_by_object
    model_name = params[:object_type]
    klass = ::OpenProject::Acts::Watchable::Registry.instance(model_name)
    @watched = klass&.find(params[:object_id])
    render_404 unless @watched
  end

  def find_project
    @project = @watched.project
  end

  def set_watcher(user, watching)
    @watched.set_watcher(user, watching)
    redirect_back(fallback_location: home_url)
  end

  def deny_access_unless_visible
    deny_access unless @watched.visible?(User.current)
  end
end
