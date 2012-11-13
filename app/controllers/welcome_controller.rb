#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class WelcomeController < ApplicationController
  def index
    @news     = current_user.latest_news
    @projects = current_user.latest_projects
  end

  def robots
    @projects = Project.active.public

    respond_to do |format|
      format.text # { render :layout => false }
    end
  end
  caches_action :robots

private

  def current_user
    User.current
  end
end
