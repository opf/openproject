#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'rack/utils'

class WorkPackages::AutoCompletesController < ::ApplicationController
  before_action :on_no_valid_scope_404

  def index
    @work_packages = work_package_with_id | work_packages_by_subject_or_id

    respond_to do |format|
      format.html do render layout: false end
      format.any(:xml, :json) { render request.format.to_sym => wp_hashes_with_string(@work_packages) }
    end
  end

  private

  def on_no_valid_scope_404
    scope = determine_scope
    if scope.nil?
      render_404

      return false
    end
  end

  def work_package_with_id
    scope = determine_scope
    query_term = params[:q].to_s

    if query_term =~ /\A\d+\z/
      scope.visible.where(id: query_term.to_i)
    else
      []
    end
  end

  def work_packages_by_subject_or_id
    scope = determine_scope
    query_term = params[:q].to_s

    if query_term =~ /\A\d+\z/
      sql_query = ["#{WorkPackage.table_name}.subject LIKE :q OR
                   CAST(#{WorkPackage.table_name}.id AS CHAR(13)) LIKE :q",
                   { q: "%#{query_term}%" }]
    else
      sql_query = ["LOWER(#{WorkPackage.table_name}.subject) LIKE :q",
                   { q: "%#{query_term.downcase}%" }]
    end

    # The filter on subject in combination with the ORDER BY on id
    # seems to trip MySql's usage of indexes on the order statement
    # I haven't seen similar problems on postgresql but there might be as the
    # data at hand was not very large.
    #
    # For MySql we are therefore helping the DB optimizer to use the correct index

    if ActiveRecord::Base.connection_config[:adapter] == 'mysql2'
      scope = scope.from("#{WorkPackage.table_name} USE INDEX(PRIMARY)")
    end

    scope
      .visible
      .where(sql_query)
      .order("#{WorkPackage.table_name}.id ASC") # :id does not work because...
      .limit(10)
      .includes(:type)
  end

  def wp_hashes_with_string(work_packages)
    work_packages.map do |work_package|
      wp_hash = Hash.new
      work_package.attributes.each do |key, value| wp_hash[key] = Rack::Utils.escape_html(value) end
      wp_hash['to_s'] = Rack::Utils.escape_html(work_package.to_s)
      wp_hash
    end
  end

  def find_project
    project_id = (params[:work_package] && params[:work_package][:project_id]) || params[:project_id]
    return nil unless project_id
    Project.find_by(id: project_id)
  end

  def determine_scope
    @scope ||= begin
      project = find_project

      if params[:scope] == 'relatable'
        return nil unless project

        Setting.cross_project_work_package_relations? ? WorkPackage.all : project.work_packages
      elsif params[:scope] == 'all' || project.nil?
        WorkPackage.all
      else
        project.work_packages
      end
    end
  end
end
