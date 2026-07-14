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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Backlogs::WorkPackages::UpdateService
  attr_reader :user, :work_package

  def initialize(user:, work_package:)
    @user = user
    @work_package = work_package
  end

  def call(list_type: nil, list_id: nil, position: nil, prev_id: nil)
    result = nil

    WorkPackage.transaction do
      result = resolve_required_attributes(list_type:, list_id:)
        .bind { |attrs| ::WorkPackages::UpdateService.new(user:, model: work_package).call(**attrs) }
        .on_success do |call|
          # A blank prev_id ("") is meaningful: it means "insert at the top of
          # the list", so a truthy check is used here. A blank position is not
          # meaningful (it would cast to nil and move to the top unintentionally),
          # so `position.present?` is used instead.
          if prev_id
            call.result.move_after(prev_id:)
          elsif position.present?
            call.result.move_after(position:)
          end
        end

      # The inner service raises ActiveRecord::Rollback when its result is a
      # failure, but that raise happens inside its own transaction, which joins
      # this one and swallows it. Re-raise here so a failure after the work
      # package row was already written cannot half-commit the move.
      raise ActiveRecord::Rollback if result.failure?
    end

    result
  end

  private

  def resolve_required_attributes(list_type:, list_id:)
    if list_type.present? || list_id.present?
      attributes_result_from_list(list_type, list_id)
    else
      ServiceResult.failure(message: I18n.t("backlogs.work_packages.update_service.missing_target"))
    end
  end

  def attributes_result_from_list(list_type, list_id)
    target = Backlogs::Target.from_list(list_type, list_id)

    if target
      ServiceResult.success(result: target.attributes)
    else
      ServiceResult.failure(message: I18n.t("backlogs.work_packages.update_service.invalid_target_type"))
    end
  end
end
