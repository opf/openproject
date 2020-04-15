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

class RbStoriesController < RbApplicationController
  include OpenProject::PDFExport::ExportCard

  # This is a constant here because we will recruit it elsewhere to whitelist
  # attributes. This is necessary for now as we still directly use `attributes=`
  # in non-controller code.
  PERMITTED_PARAMS = [:id, :status_id, :version_id,
                      :story_points, :type_id, :subject, :author_id,
                      :sprint_id]

  def create
    call = Stories::CreateService
           .new(user: current_user)
           .call(attributes: story_params,
                 prev: params[:prev])

    respond_with_story(call)
  end

  def update
    story = Story.find(params[:id])

    call = Stories::UpdateService
           .new(user: current_user, story: story)
           .call(attributes: story_params,
                 prev: params[:prev])

    unless call.success?
      # reload the story to be able to display it correctly
      call.result.reload
    end

    respond_with_story(call)
  end

  private

  def respond_with_story(call)
    status = call.success? ? 200 : 400
    story = call.result

    respond_to do |format|
      format.html { render partial: 'story', object: story, status: status }
    end
  end

  def story_params
    params.permit(PERMITTED_PARAMS).merge(project: @project).to_h
  end
end
