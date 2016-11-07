#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module OpenProject::Costs
  class WorkPackageFilter < ::Queries::BaseFilter

    alias :project :context
    alias :project= :context=

    def allowed_values
      CostObject
        .where(project_id: project)
        .order('subject ASC')
        .pluck(:subject, :id)
    end

    def available?
      project &&
        project.module_enabled?(:costs_module)
    end

    def self.key
      :cost_object_id
    end

    def order
      14
    end

    def type
      :list_optional
    end

    def human_name
      WorkPackage.human_attribute_name(:cost_object)
    end
  end
end

