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

class UpdateWorkPackageService
  attr_accessor :user, :work_package, :permitted_params

  def initialize(user:, work_package:, permitted_params: nil, send_notifications: true)
    self.user = user
    self.work_package = work_package
    self.permitted_params = permitted_params

    JournalObserver.instance.send_notification = send_notifications
  end

  def update
    work_package.update_by!(user, effective_params)
  end

  def save
    work_package.save
  end

  private

  def effective_params
    effective_params = HashWithIndifferentAccess.new

    if permitted_params[:journal_notes]
      notes = { notes: permitted_params.delete(:journal_notes) }

      effective_params.merge!(notes) if user.allowed_to?(:add_work_package_notes, work_package.project)
    end

    effective_params.merge!(permitted_params) if user.allowed_to?(:edit_work_packages, work_package.project)

    effective_params
  end
end
