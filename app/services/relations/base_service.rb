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

class Relations::BaseService < BaseServices::BaseCallable
  include Contracted
  include Shared::ServiceContext
  include Relations::Concerns::Rescheduling

  attr_accessor :user

  def initialize(user:)
    super()
    self.user = user
  end

  private

  def update_relation(relation, attributes)
    relation.attributes = relation.attributes.merge attributes

    success, errors = validate_and_save(relation, user)

    result = ServiceResult.new success:, errors:, result: relation

    if success && relation.follows?
      reschedule_result = reschedule_successor(relation)
      result.merge!(reschedule_result)
    end

    result
  end

  def set_defaults(relation)
    if relation.follows?
      relation.lag ||= 0
    else
      relation.lag = nil
    end
  end
end
