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

class DeleteContract < ModelContract
  class << self
    def delete_permission(permission = nil)
      if permission
        @delete_permission = permission
      end

      @delete_permission
    end
  end

  validate :user_allowed

  def user_allowed
    unless authorized?
      errors.add :base, :error_unauthorized
    end
  end

  protected

  def validate_model?
    false
  end

  def authorized?
    permission = self.class.delete_permission

    case permission
    when :admin
      user.admin? && user.active?
    when Proc
      instance_exec(&permission)
    when Symbol
      model.project && user.allowed_in_project?(permission, model.project)
    else
      raise ArgumentError, "#{self.class} used without delete_permission. Set a  Proc, or project-based permission symbol"
    end
  end
end
