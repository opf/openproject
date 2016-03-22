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

##
# Create journal for the given user and note.
# Does not change the work package itself.

class AddWorkPackageNoteService
  attr_accessor :user, :work_package

  class << self
    attr_accessor :contract
  end

  self.contract = WorkPackages::CreateNoteContract

  def initialize(user:, work_package:)
    self.user = user
    self.work_package = work_package

    self.contract = self.class.contract.new(work_package, user)
  end

  def call(notes, send_notifications: true)
    JournalManager.with_send_notifications send_notifications do
      work_package.add_journal(user, notes)

      result, errors = validate_and_save

      ServiceResult.new(result, errors)
    end
  end

  private

  attr_accessor :contract

  def validate_and_save
    if !contract.validate
      return false, contract.errors
    elsif !work_package.save_journals
      return false, work_package.errors
    else
      return true, work_package.errors
    end
  end
end
