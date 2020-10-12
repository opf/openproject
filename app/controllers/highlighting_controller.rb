#-- encoding: UTF-8
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

class HighlightingController < ApplicationController
  before_action :determine_freshness
  skip_before_action :check_if_login_required, only: [:styles]

  def styles
    response.content_type = Mime[:css]
    request.format = :css

    expires_in 1.year, public: true, must_revalidate: false
    if stale?(last_modified: Time.zone.parse(@max_updated_at), etag: @highlight_version_tag, public: true)
      OpenProject::Cache.fetch('highlighting/styles', @highlight_version_tag) do
        render template: 'highlighting/styles', formats: [:css]
      end
    end
  end

  private

  def determine_freshness
    @max_updated_at = helpers.highlight_css_updated_at.to_s || Time.now.iso8601
    @highlight_version_tag = helpers.highlight_css_version_tag(@max_updated_at)
  end
end
