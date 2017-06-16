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

class WorkPackagesController < ApplicationController
  include QueriesHelper
  include PaginationHelper
  include OpenProject::ClientPreferenceExtractor

  accept_key_auth :index, :show

  before_action :authorize_on_work_package, only: :show
  before_action :find_optional_project,
                :protect_from_unauthorized_export, only: :index

  before_action :load_query, only: :index, unless: ->() { request.format.html? }
  before_action :load_work_packages, only: :index, if: ->() { request.format.atom? }

  before_action :set_gon_settings

  def show
    respond_to do |format|
      format.html do
        render :show, locals: { work_package: work_package }, layout: 'angular'
      end

      format.any(*WorkPackage::Exporter.single_formats) do
        export_single(request.format.symbol)
      end

      format.atom do
        atom_journals
      end
    end
  end

  def index
    respond_to do |format|
      format.html do
        render :index, locals: { query: @query, project: @project },
                       layout: 'angular'
      end

      format.any(*WorkPackage::Exporter.list_formats) do
        export_list(request.format.symbol)
      end

      format.atom do
        atom_list
      end
    end
  end

  current_menu_item :index do
    :work_packages
  end

  protected

  def set_gon_settings
    gon.settings = client_preferences
    gon.settings[:enabled_modules] = project ? project.enabled_modules.collect(&:name) : []
  end

  def export_list(mime_type)
    exporter = WorkPackage::Exporter.for_list(mime_type)
    export = exporter.list(@query, params)

    if export.error?
      flash[:error] = export.message
      redirect_back(fallback_location: index_redirect_path)
    else
      send_data(export.content,
                type: export.mime_type,
                filename: export.title)
    end
  end

  def export_single(mime_type)
    exporter = WorkPackage::Exporter.for_single(mime_type)
    export = exporter.single(work_package, params)

    if export.error?
      flash[:error] = export.message
      redirect_back(fallback_location: work_package_path(work_packages))
    else
      send_data(export.content,
                type: export.mime_type,
                filename: export.title)
    end
  end

  def atom_journals
    render template: 'journals/index',
           layout: false,
           content_type: 'application/atom+xml',
           locals: { title: "#{Setting.app_title} - #{work_package}",
                     journals: journals }
  end

  def atom_list
    render_feed(@work_packages,
                title: "#{@project || Setting.app_title}: #{l(:label_work_package_plural)}")
  end

  def authorize_on_work_package
    deny_access unless work_package
  end

  def protect_from_unauthorized_export
    if supported_export_formats.include?(params[:format]) &&
       !User.current.allowed_to?(:export_work_packages, @project, global: @project.nil?)

      deny_access
      false
    end
  end

  def supported_export_formats
    %w[atom rss] + WorkPackage::Exporter.list_formats.map(&:to_s)
  end

  def load_query
    @query ||= retrieve_query_v3
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def per_page_param
    case params[:format]
    when 'atom'
      Setting.feeds_limit.to_i
    else
      super
    end
  end

  def project
    @project ||= work_package ? work_package.project : nil
  end

  def work_package
    @work_package ||= WorkPackage.visible(current_user).find_by(id: params[:id])
  end

  def journals
    @journals ||= work_package
                  .journals
                  .changing
                  .includes(:user)
                  .order("#{Journal.table_name}.created_at ASC").to_a
    @journals.reverse_order if current_user.wants_comments_in_reverse_order?
    @journals
  end

  def index_redirect_path
    if @project
      project_work_packages_path(@project)
    else
      work_packages_path
    end
  end

  private

  def load_work_packages
    @results = @query.results
    @work_packages = if @query.valid?
                       @results
                         .sorted_work_packages
                         .page(page_param)
                         .per_page(per_page_param)
                     else
                       []
                     end
  end

  def login_back_url_params
    params.permit(:query_id, :state, :query_props)
  end
end
