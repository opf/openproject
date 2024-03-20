#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require 'rack/utils'

class WorkPackages::AutoCompletesController < ApplicationController
  def index
    @work_packages = work_packages_matching_query_prop

    respond_to do |format|
      format.json { render request.format.to_sym => wp_hashes_with_string(@work_packages) }
    end
  end

  private

  def work_packages_matching_query_prop
    Query.new.tap do |query|
      query.add_filter(:typeahead, '**', params[:q])
      query.sort_criteria = [%i[updated_at desc]]
      query.include_subprojects = true
    end
      .results
      .work_packages
      .limit(10)
  end

  def wp_hashes_with_string(work_packages)
    work_packages.map do |work_package|
      work_package.attributes.merge('to_s' => work_package.to_s)
    end
  end
end
