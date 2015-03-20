#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'rack/utils'

class WorkPackages::AutoCompletesController < ApplicationController
  before_filter :find_project

  def index
    @work_packages = []
    q = params[:q].to_s

    if q.present?
      query = (params[:scope] == 'all' && Setting.cross_project_work_package_relations?) ? WorkPackage : @project.work_packages

      @work_packages |= query.visible.find_all_by_id(q.to_i) if q =~ /\A\d+\z/

      @work_packages |= query.visible.find(:all,
                                           limit: 10,
                                           order: "#{WorkPackage.table_name}.id ASC",
                                           conditions: ["LOWER(#{WorkPackage.table_name}.subject) LIKE :q OR CAST(#{WorkPackage.table_name}.id AS CHAR(13)) LIKE :q", { q: "%#{q.downcase}%" }])
    end

    respond_to do |format|
      format.html { render layout: false }
      format.any(:xml, :json) { render request.format.to_sym => wp_hash_with_string }
    end
  end

  private

  def wp_hash_with_string
    @work_packages.map do |wp|
      Hash[wp.attributes.map do |key, value|
        [key, Rack::Utils.escape_html(value)]
      end << ['to_s', Rack::Utils.escape_html(wp.to_s)]]
    end
  end

  def find_project
    project_id = (params[:work_package] && params[:work_package][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
