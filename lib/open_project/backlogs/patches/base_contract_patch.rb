#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

module OpenProject::Backlogs::Patches::BaseContractPatch
  def self.included(base)
    base.class_eval do
      validate :validate_has_parents_fixed_version
      validate :validate_parent_work_package_relation

      private

      def validate_has_parents_fixed_version
        if model.is_task? &&
           model.parent && model.parent.in_backlogs_type? &&
           model.fixed_version_id != model.parent.fixed_version_id
          errors.add :fixed_version_id, :task_version_must_be_the_same_as_story_version
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
end
