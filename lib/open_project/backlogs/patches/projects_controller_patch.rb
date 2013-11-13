#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013 the OpenProject Team
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

require_dependency 'projects_controller'

module OpenProject::Backlogs::Patches::ProjectsControllerPatch
  def self.included(base)
    base.class_eval do
      include InstanceMethods

      alias_method_chain :settings, :backlogs_settings
    end
  end

  module InstanceMethods
    def settings_with_backlogs_settings
      settings_without_backlogs_settings
      @statuses = Status.all
    end

    def project_done_statuses
      selected_statuses = (params[:statuses] || []).map do |work_package_status|
        Status.find(work_package_status[:status_id].to_i)
      end.compact

      @project.done_statuses = selected_statuses
      @project.save!

      flash[:notice] = l(:notice_successful_update)

      redirect_to :action => 'settings', :id => @project, :tab => 'backlogs_settings'
    end

    def rebuild_positions
      @project.rebuild_positions
      flash[:notice] = l('backlogs.positions_rebuilt_successfully')

      redirect_to :action => 'settings', :id => @project, :tab => 'backlogs_settings'
    rescue ActiveRecord::ActiveRecordError
      flash[:error] = l('backlogs.positions_could_not_be_rebuilt')

      logger.error("Tried to rebuild positions for project #{@project.identifier.inspect} but could not...")
      logger.error($!)
      logger.error($@)

      redirect_to :action => 'settings', :id => @project, :tab => 'backlogs_settings'
    end
  end
end

ProjectsController.send(:include, OpenProject::Backlogs::Patches::ProjectsControllerPatch)
