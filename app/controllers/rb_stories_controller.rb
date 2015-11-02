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

class RbStoriesController < RbApplicationController
  include OpenProject::PdfExport::ExportCard

  # This is a constant here because we will recruit it elsewhere to whitelist
  # attributes. This is necessary for now as we still directly use `attributes=`
  # in non-controller code.
  PERMITTED_PARAMS = [:id, :status_id, :fixed_version_id,
                      :story_points, :type_id, :subject, :author_id, :prev,
                      :sprint_id]

  def create
    params['author_id'] = User.current.id
    prev = params.delete('prev')
    story = Story.create_and_position(story_params, {project: @project,
                                                    author: User.current},
                                                    prev)
    status = (story.id ? 200 : 400)

    respond_to do |format|
      format.html { render partial: 'story', object: story, status: status }
    end
  end

  def update
    story = Story.find(params[:id])
    prev = params.delete('prev')
    result = story.update_and_position!(story_params, @project, prev)
    story.reload
    status = (result ? 200 : 400)

    respond_to do |format|
      format.html { render partial: 'story', object: story, status: status }
    end
  end

private

  def story_params
    params.permit(PERMITTED_PARAMS)
  end
end
