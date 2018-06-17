#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class WorkPackages::UpdateFollowersService
  attr_accessor :user,
                :work_package,
                :is_deleted

  def initialize(user:, work_package:, is_deleted: false)
    self.user = user
    self.work_package = work_package
    self.is_deleted = is_deleted
  end

  def call(attributes)
    operation_success = true

    if is_deleted || attributes.include?(:status_id)
      modified = update_followers(is_deleted || work_package.closed?)

      set_journal_note(modified, is_deleted || work_package.closed?)

      operation_success = modified.all? { |wp| wp.save(validate: false) }
    end

    result = ServiceResult.new(success: operation_success,
                               result: work_package)

    unless modified.nil?
      modified.each do |wp|
        result.add_dependent!(ServiceResult.new(success: !wp.changed?, result: wp))
      end
    end

    result
  end

  private

  def update_followers(work_package_closed)
    work_package.precedes.includes(:status).select do |follower|

      if !work_package_closed && !follower.blocked_by_predecessors
        follower.blocked_by_predecessors = true
      elsif work_package_closed && follower.blocked_by_predecessors

        has_open_predecessors = follower.follows.includes(:status)
          .where(statuses: { is_closed: false})
          .where.not(id: work_package.id).exists?

        follower.blocked_by_predecessors = has_open_predecessors

      end

      follower.changed?
    end
  end

  def set_journal_note(work_packages, work_package_closed)
    work_packages.each do |wp|
      if work_package_closed
        wp.journal_notes = I18n.t('work_package.unblocked_by_predecessor_status_changes', predecessor: "##{work_package.id}")
      else
        wp.journal_notes = I18n.t('work_package.blocked_by_predecessor_status_changes', predecessor: "##{work_package.id}")
      end
    end
  end
end
