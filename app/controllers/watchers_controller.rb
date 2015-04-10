#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class WatchersController < ApplicationController
  before_filter :find_watched_by_object, except: [:destroy]
  before_filter :find_watched_by_id, only: [:destroy]
  before_filter :find_project
  before_filter :require_login, :check_project_privacy, only: [:watch, :unwatch]
  before_filter :authorize, only: [:new, :create, :destroy]

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

  def new
    @watcher = Watcher.new(params[:watcher])
    @watcher.watchable = @watched
    @watcher.save if request.post?

    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'watchers', partial: 'watchers/watchers', locals: { watched: @watched }
        end
      end
    end
  rescue ::ActionController::RedirectBackError
    render text: 'Watcher added.', layout: true
  end

  # TODO: remove this and replace with proper action
  alias :create :new

  def destroy
    @watched.set_watcher(@watch.user, false)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'watchers', partial: 'watchers/watchers', locals: { watched: @watched }
        end
      end
    end
  end

  private

  def find_watched_by_object
    klass = params[:object_type].singularize.camelcase.constantize
    return false unless klass.respond_to?('watched_by') and
                        klass.ancestors.include? Redmine::Acts::Watchable and
                        params[:object_id].to_s =~ /\A\d+\z/
    @watched = klass.find(params[:object_id])
  rescue
    render_404
  end

  def find_watched_by_id
    return false unless params[:id].to_s =~ /\A\d+\z/
    @watch = Watcher.find(params[:id], include: { watchable: [:project] })
    @watched = @watch.watchable
  end

  def find_project
    @project = @watched.project
  end

  def set_watcher(user, watching)
    @watched.set_watcher(user, watching)

    respond_to do |format|
      format.html { redirect_to :back }
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

        render action: 'replace_selectors'
      end
    end
  rescue ::ActionController::RedirectBackError
    render text: (watching ? 'Watcher added.' : 'Watcher removed.'), layout: true
  end
end
