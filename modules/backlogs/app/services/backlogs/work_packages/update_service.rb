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
  attr_accessor :user, :story

  def initialize(user:, story:)
    self.user = user
    self.story = story
  end

  def call(direction: nil, list_type: nil, list_id: nil, position: nil, prev_id: nil)
    resolve_required_attributes(direction:, list_type:, list_id:)
      .bind { |attrs| ::WorkPackages::UpdateService.new(user:, model: story).call(**attrs) }
      .on_success do |call|
        if prev_id
          call.result.move_after(prev_id:)
        elsif position
          call.result.move_after(position:)
        end
      end
  end

  private

  def resolve_required_attributes(direction:, list_type:, list_id:)
    if list_type.present? && direction
      ServiceResult.failure(message: I18n.t("backlogs.stories.update_service.ambiguous_target"))
    elsif list_type.present?
      attributes_result_from_list(list_type, list_id)
    elsif direction
      attributes_result_from_direction(direction)
    else
      ServiceResult.failure(message: I18n.t("backlogs.stories.update_service.missing_target"))
    end
  end

  def attributes_result_from_list(list_type, list_id)
    target = Backlogs::MoveTarget.from_list(list_type, list_id)

    if target
      ServiceResult.success(result: target.attributes)
    else
      ServiceResult.failure(message: I18n.t("backlogs.stories.update_service.invalid_target_type"))
    end
  end

  def attributes_result_from_direction(direction)
    if direction.in? %w(higher highest lower lowest)
      ServiceResult.success(result: { move_to: direction })
    else
      ServiceResult.failure(message: I18n.t("backlogs.stories.update_service.invalid_direction"))
    end
  end
end
