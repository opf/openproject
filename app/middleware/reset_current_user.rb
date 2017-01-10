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

##
# Resets `User.current` between requests. This is to make sure that
# no data leaks occur. One case specifically where this did occur before
# is when a user is trying to authorize through OmniAuth.
# During the login an account may be created on the fly.
# If this failed due to some reason, e.g. an already taken email address,
# `User.current` still had the value of the last processed request.
# Through this users were able to see random other user's full names
# in the header.
class ResetCurrentUser
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    reset_current_user!
    app.call env
  end

  def reset_current_user!
    User.current = nil
  end
end
