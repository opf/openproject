#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

class Relations::BaseService
  include Contracted
  include Shared::ServiceContext

  attr_accessor :user

  def initialize(user:)
    self.user = user
  end

  private

  def update_relation(model, attributes)
    model.attributes = model.attributes.merge attributes

    success, errors = validate_and_save(model, user)
    success, errors = retry_with_inverse_for_relates(model, errors) unless success

    result = ServiceResult.new success: success, errors: errors, result: model

    if success && model.follows?
      reschedule_result = reschedule(model)
      result.merge!(reschedule_result)
    end

    result
  end

  def set_defaults(model)
    if Relation::TYPE_FOLLOWS == model.relation_type
      model.delay ||= 0
    else
      model.delay = nil
    end
  end

  def reschedule(model)
    schedule_result = WorkPackages::SetScheduleService
                      .new(user: user, work_package: model.to)
                      .call

    # The to-work_package will not be altered by the schedule service so
    # we do not have to save the result of the service.
    save_result = if schedule_result.success?
                    schedule_result.dependent_results.all? { |dr| !dr.result.changed? || dr.result.save }
                  end || false

    schedule_result.success = save_result

    schedule_result
  end

  def retry_with_inverse_for_relates(model, errors)
    if errors.symbols_for(:base).include?(:"typed_dag.circular_dependency") &&
       model.canonical_type == Relation::TYPE_RELATES
      model.from, model.to = model.to, model.from

      validate_and_save(model, user)
    else
      [false, errors]
    end
  end
end
