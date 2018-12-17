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

module OpenProject::Costs::Patches::ProjectsControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      before_action :own_total_hours, only: [:show]
    end
  end

  module InstanceMethods
    def own_total_hours
      if User.current.allowed_to?(:view_own_time_entries, @project)
        cond = @project.project_condition(Setting.display_subprojects_work_packages?)
        @total_hours = TimeEntry.visible.includes(:project).where(cond).sum(:hours).to_f
      end
    end
  end
end
