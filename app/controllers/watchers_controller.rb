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

class WatchersController < ApplicationController
  before_action :find_watched_by_object, except: [:destroy]
  before_action :find_project
  before_action :require_login, :check_project_privacy, only: [:watch, :unwatch]

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

    respond_to do |format|
      format.html do redirect_to :back end
      format.js do
        if params[:replace].present?
          if params[:replace].is_a? Array
            @replace_selectors = params[:replace]
          else
            @replace_selectors = params[:replace].split(',').map(&:strip)
          end
        else
          @replace_selectors = ['#watcher']
        end
        @user = user
        render template: 'watchers/set_watcher'
      end
    end
  rescue ::ActionController::RedirectBackError
    render text: (watching ? 'Watcher added.' : 'Watcher removed.'), layout: true
  end
end
