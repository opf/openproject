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

class AIAssistance::MenusController < ApplicationController
  include AIAssistance::Scoped

  # The header loads the menu into a turbo frame on every page. A place the user cannot see
  # or use gives an empty frame, not an error inside the header: the header asks for any
  # id in the URL.
  skip_before_action :find_place
  skip_before_action :authorize_place
  authorization_checked! :show
  before_action :find_place_or_render_empty

  def show
    render AI::Assistance::MenuButtonComponent.new(place: @place, skills: available_skills), layout: false
  end

  private

  def find_place_or_render_empty
    @place = AI::Assistance::Place.from_params(params, user: current_user)
    return render_empty unless @place&.allowed?(current_user) && available_skills.any?

    @work_package = @place.work_package
    @project = @place.project
  end

  def render_empty
    render AI::Assistance::MenuButtonComponent.new(place: @place || AI::Assistance::Place.new, empty: true), layout: false
  end
end
