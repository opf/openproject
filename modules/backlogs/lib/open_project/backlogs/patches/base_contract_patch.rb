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

module OpenProject::Backlogs::Patches::BaseContractPatch
  extend ActiveSupport::Concern

  included do
    attribute :story_points,
              writable: -> { model.backlogs_enabled? }
    attribute :backlog_bucket,
              permission: :manage_sprint_items
    attribute :sprint,
              # This also covers the check for backlogs being active
              permission: :manage_sprint_items

    validate :backlog_bucket_xor_sprint
    validate :backlog_bucket_belongs_to_project
    validate :validate_sprint_is_assignable

    def assignable_sprints
      if model.project
        Sprint.assignable(project: model.project, user:)
      else
        Sprint.none
      end
    end

    private

    def backlog_bucket_xor_sprint
      return unless model.backlog_bucket && model.sprint

      errors.add :base, :backlog_bucket_xor_sprint
    end

    def backlog_bucket_belongs_to_project
      return unless model.backlog_bucket
      return if model.backlog_bucket.project == model.project

      errors.add :backlog_bucket, :backlog_bucket_from_another_project
    end

    def validate_sprint_is_assignable
      if model.sprint_id &&
         model.sprint_id_changed? &&
         !assignable_sprints.exists?(id: model.sprint_id)
        errors.add :sprint, :not_assignable
      end
    end
  end
end
