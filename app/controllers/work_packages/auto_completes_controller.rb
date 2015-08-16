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
  def index
    scope = determine_scope
    if scope.nil?
      render_404
      return
    end

    query_term = params[:q].to_s
    @work_packages = []
    # query for exact ID matches first, to make an exact match the first result of autocompletion
    if query_term =~ /\A\d+\z/
      @work_packages |= scope.visible.find_all_by_id(query_term.to_i)
    end

    sql_query = ["LOWER(#{WorkPackage.table_name}.subject) LIKE :q OR
                  CAST(#{WorkPackage.table_name}.id AS CHAR(13)) LIKE :q",
                 { q: "%#{query_term.downcase}%" }]

    @work_packages |= scope.visible
                      .where(sql_query)
                      .order("#{WorkPackage.table_name}.id ASC") # :id does not work because...
                      .limit(10)

    respond_to do |format|
      format.html do render layout: false end
      format.any(:xml, :json) { render request.format.to_sym => wp_hashes_with_string }
    end
  end

  private

  def wp_hashes_with_string
    @work_packages.map do |work_package|
      wp_hash = Hash.new
      work_package.attributes.each do |key, value| wp_hash[key] = Rack::Utils.escape_html(value) end
      wp_hash['to_s'] = Rack::Utils.escape_html(work_package.to_s)
      wp_hash
    end
  end

  def find_project
    project_id = (params[:work_package] && params[:work_package][:project_id]) || params[:project_id]
    return nil unless project_id
    Project.find_by_id(project_id)
  end

  def determine_scope
    project = find_project

    if params[:scope] == 'relatable'
      return nil unless project

      Setting.cross_project_work_package_relations? ? WorkPackage.scoped : project.work_packages
    elsif params[:scope] == 'all' || project.nil?
      WorkPackage.scoped
    else
      project.work_packages
    end
  end
end
