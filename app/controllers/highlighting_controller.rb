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

class HighlightingController < ApplicationController
  skip_before_action :check_if_login_required, only: [:styles]
  no_authorization_required! :styles

  def styles
    response.content_type = Mime[:css]
    request.format = :css
    cache_key = Highlighting::Registry.cache_key

    expires_in 1.year, public: true, must_revalidate: false
    return unless stale?(etag: cache_key, public: true)

    # The cached value has to be rendered explicitly. Rendering inside the block only
    # populates the response on a miss, leaving a hit with nothing rendered at all.
    css = OpenProject::Cache.fetch(["highlighting/styles", cache_key]) do
      render_to_string template: "highlighting/styles", formats: [:css]
    end

    render plain: css, content_type: Mime[:css].to_s
  end
end
