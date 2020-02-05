#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class WatchersController < ApplicationController
  before_action :find_watched_by_object
  before_action :find_project
  before_action :require_login, :check_project_privacy, only: %i[watch unwatch]

  def watch
    if @watched.respond_to?(:visible?) && !@watched.visible?(User.current)
      render_403
    else
      set_watcher(User.current, true)
    end
  end

  def unwatch
    set_watcher(User.current, false)
  end

  private

  def find_watched_by_object
    klass = params[:object_type].singularize.camelcase.constantize

    return false unless klass.respond_to?('watched_by') and
                        klass.ancestors.include? Redmine::Acts::Watchable and
                        params[:object_id].to_s =~ /\A\d+\z/

    unless @watched = klass.find(params[:object_id])
      render_404
    end
  end

  def find_project
    @project = @watched.project
  end

  def set_watcher(user, watching)
    @watched.set_watcher(user, watching)
    redirect_back(fallback_location: home_url)
  end
end
