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

module Budgets::Patches::WorkPackagePatch
  extend ActiveSupport::Concern

  included do
    belongs_to :budget, inverse_of: :work_packages, optional: true

    validate :validate_budget
  end

  def validate_budget
    # Also re-validate when the work package is moved to another project, since
    # the set of valid budgets is project-scoped. Otherwise a budget belonging
    # to the source project would silently survive the move.
    if (budget_id_changed? || project_id_changed?) &&
       !(budget_id.blank? || project.budget_ids.include?(budget_id))
      errors.add :budget, :inclusion
    end
  end

  # Wraps the association to get the Cost Object subject.  Needed for the
  # Query and filtering
  def budget_subject
    budget&.subject
  end
end
