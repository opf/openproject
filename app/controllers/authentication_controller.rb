#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class AuthenticationController < ApplicationController
  unloadable
  helper :timelines

  before_filter :disable_api
  before_filter :require_login

  accept_key_auth :index

  def index
    respond_to do |format|
      format.html
    end
  end
end
