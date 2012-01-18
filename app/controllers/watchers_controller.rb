#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class WatchersController < ApplicationController
  before_filter :find_project
  before_filter :require_login, :check_project_privacy, :only => [:watch, :unwatch]
  before_filter :authorize, :only => [:new, :destroy]
  before_filter :authorize_access_to_object, :only => [:new, :destroy]

  verify :method => :post,
         :only => [ :watch, :unwatch ],
         :render => { :nothing => true, :status => :method_not_allowed }

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
    params[:user_ids].each do |user_id|
      @watcher = Watcher.new((params[:watcher] || {}).merge({:user_id => user_id}))
      @watcher.watchable = @watched
      @watcher.save if request.post?
    end if params[:user_ids].present?

    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'watchers', :partial => 'watchers/watchers', :locals => {:watched => @watched}
        end
      end
    end
  rescue ::ActionController::RedirectBackError
    render :text => 'Watcher added.', :layout => true
  end

  def destroy
    @watched.set_watcher(Principal.find(params[:user_id]), false) if request.post?
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'watchers', :partial => 'watchers/watchers', :locals => {:watched => @watched}
        end
      end
    end
  end

private
  def find_project
    klass = Object.const_get(params[:object_type].camelcase)
    return false unless klass.respond_to?('watched_by')
    @watched = klass.find(params[:object_id])
    @project = @watched.project
  rescue
    render_404
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

        render :action => 'replace_selectors'
      end
    end
  rescue ::ActionController::RedirectBackError
    render :text => (watching ? 'Watcher added.' : 'Watcher removed.'), :layout => true
  end

  def authorize_access_to_object
    permission = ''
    case params[:action]
    when 'new'
      permission << 'add_'
    when 'destroy'
      permission << 'delete_'
    end

    # Ends up like: :delete_wiki_page_watchers
    permission << "#{@watched.class.name.underscore}_watchers"

    if User.current.allowed_to?(permission.to_sym, @project)
      return true
    else
      deny_access
    end
  end

end
