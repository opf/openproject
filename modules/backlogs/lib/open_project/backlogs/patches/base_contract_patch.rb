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

module OpenProject::Backlogs::Patches::BaseContractPatch
  extend ActiveSupport::Concern

  included do
    attribute :remaining_hours
    attribute :story_points

    validate :validate_has_parents_version
    validate :validate_parent_work_package_relation

    private

    def validate_has_parents_version
      if model.is_task? &&
         model.parent && model.parent.in_backlogs_type? &&
         model.version_id != model.parent.version_id
        errors.add :version_id, :task_version_must_be_the_same_as_story_version
      end
    end

    def validate_parent_work_package_relation
      if model.parent && parent_work_package_relationship_spanning_projects?
        errors.add(:parent_id,
                   :parent_child_relationship_across_projects,
                   work_package_name: model.subject,
                   parent_name: model.parent.subject)
      end
    end

    def parent_work_package_relationship_spanning_projects?
      model.is_task? &&
        model.parent.in_backlogs_type? &&
        model.parent.project_id != model.project_id
    end
  end
end
