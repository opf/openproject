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

class Scm::AuthoriziationPolicy
  attr_reader :project, :user

  def initialize(project, user)
    @user = user
    @project = project
  end

  ##
  # Determines the authorization status for the user of this project
  # for a given repository request.
  # May be overridden by descendents when more than the read/write distinction
  # is necessary.
  def authorized?(params)
    (readonly_request?(params) && read_access?) || write_access?
  end

  protected

  ##
  # Determines whether the given request is a read access
  # Must be implemented by descendents of this policy.
  def readonly_request?(_params)
    raise NotImplementedError
  end

  ##
  # Returns whether the user has read access permission to the repository
  def read_access?
    user.allowed_to?(:browse_repository, project)
  end

  ##
  # Returns whether the user has read/write access permission to the repository
  def write_access?
    user.allowed_to?(:commit_access, project)
  end
end
