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

class FavoritesController < ApplicationController
  before_action :find_favored_by_object
  before_action :require_login
  no_authorization_required! :favorite, :unfavorite

  def favorite
    if @favored.visible?(User.current)
      set_favored(User.current, true)
    else
      render_403
    end
  end

  def unfavorite
    set_favored(User.current, false)
  end

  private

  def find_favored_by_object
    model_name = params[:object_type]
    klass = ::OpenProject::Acts::Favorable::Registry.instance(model_name)
    @favored = klass&.find(params[:object_id])
    render_404 unless @favored
  end

  def set_favored(user, favored)
    @favored.set_favored(user, favored:)

    respond_to do |format|
      format.html { redirect_back(fallback_location: home_url, status: 303) }
      format.json { head :no_content }
    end
  end
end
