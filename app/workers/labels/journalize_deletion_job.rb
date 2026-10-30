# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Labels::JournalizeDeletionJob < ApplicationJob
  queue_with_priority :below_normal

  def perform(work_package_ids:, label_id:, label_name:, user_id:)
    user = User.find_by(id: user_id) || DeletedUser.first
    cause = Journal::CausedByLabelDeletion.new(label_ids: [label_id], label_names: [label_name])

    WorkPackage.where(id: work_package_ids).find_each(batch_size: 100) do |work_package|
      journalize(work_package, user, cause, label_id)
    end
  end

  private

  def journalize(work_package, user, cause, label_id)
    OpenProject::Mutex.with_advisory_lock_transaction(work_package) do
      next if journalized?(work_package, label_id)

      Journals::CreateService.new(work_package, user).call(cause:)
    end
  end

  def journalized?(work_package, label_id)
    work_package.journals.exists?(["journals.cause @> ?", { type: "label_deleted", label_ids: [label_id] }.to_json])
  end
end
