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

# Base class of all controllers in Backlogs
class RbApplicationController < ApplicationController
  helper :rb_common

  before_action :load_sprint_and_project, :check_if_plugin_is_configured, :authorize

  skip_before_action :verify_authenticity_token, if: -> { Rails.env.test? }

  private

  # Loads the project to be used by the authorize filter to determine if
  # User.current has permission to invoke the method in question.
  def load_sprint_and_project
    # because of strong params, we want to pluck this variable out right now,
    # otherwise it causes issues where we are doing `attributes=`.
    if (@sprint_id = params.delete(:sprint_id))
      @sprint = Sprint.find(@sprint_id)
      @project = @sprint.project
    end
    # This overrides sprint's project if we set another project, say a subproject
    @project = Project.find(params[:project_id]) if params[:project_id]
  end

  def check_if_plugin_is_configured
    settings = Setting.plugin_openproject_backlogs
    if settings['story_types'].blank? || settings['task_type'].blank?
      respond_to do |format|
        format.html { render file: 'shared/not_configured' }
      end
    end
  end
end
