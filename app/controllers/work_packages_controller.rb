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
  DEFAULT_SORT_ORDER = ['parent', 'desc']
  EXPORT_FORMATS = %w[atom rss xls csv pdf]

  include QueriesHelper
  include PaginationHelper
  include SortHelper
  include OpenProject::ClientPreferenceExtractor

  accept_key_auth :index, :show

  # before_action :disable_api # TODO re-enable once API is used for any JSON request
  before_action :authorize_on_work_package, only: :show
  before_action :find_optional_project,
                :protect_from_unauthorized_export, only: :index

  before_action :load_query,
                :load_work_packages, only: :index, unless: ->() { request.format.html? }

  def show
    respond_to do |format|
      format.html do
        gon.settings = client_preferences
        gon.settings[:enabled_modules] = project ? project.enabled_modules.collect(&:name) : []

        render :show, locals: { work_package: work_package }, layout: 'angular'
      end

      format.pdf do
        export = WorkPackage::Exporter.work_package_to_pdf(work_package)

        send_data(export.render,
                  type: 'application/pdf',
                  filename: "#{project.identifier}-#{work_package.id}.pdf")
      end

      format.atom do
        render template: 'journals/index',
               layout: false,
               content_type: 'application/atom+xml',
               locals: { title: "#{Setting.app_title} - #{work_package}",
                         journals: journals }
      end
    end
  end

  def index
    respond_to do |format|
      format.html do
        gon.settings = client_preferences
        gon.settings[:enabled_modules] = @project ? @project.enabled_modules.collect(&:name) : []

        render :index, locals: { query: @query, project: @project },
                       layout: 'angular'
      end

      format.csv do
        serialized_work_packages = WorkPackage::Exporter.csv(@work_packages, @query)
        title = @query.new_record? ? l(:label_work_package_plural) : @query.name

        render csv: serialized_work_packages, filename: "#{title}.csv"
      end

      format.pdf do
        export = WorkPackage::Exporter.pdf(
          @work_packages, @project, @query, @results,
          show_descriptions: params[:show_descriptions])

        send_data(export.render,
                  type: 'application/pdf',
                  filename: 'export.pdf')
      end

      format.atom do
        render_feed(@work_packages,
                    title: "#{@project || Setting.app_title}: #{l(:label_work_package_plural)}")
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  rescue Prawn::Errors::CannotFit
    flash[:error] = I18n.t :error_pdf_export_too_many_columns
    redirect_back(fallback_location: index_work_packages_path)
  end

  current_menu_item :index do
    :work_packages
  end

  protected

  def authorize_on_work_package
    deny_access unless work_package
  end

  def protect_from_unauthorized_export
    if EXPORT_FORMATS.include?(params[:format]) &&
       !User.current.allowed_to?(:export_work_packages, @project, global: @project.nil?)

      deny_access
      false
    end
  end

  def load_query
    @query ||= retrieve_query
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def per_page_param
    case params[:format]
    when 'csv', 'pdf'
      Setting.work_packages_export_limit.to_i
    when 'atom'
      Setting.feeds_limit.to_i
    else
      super
    end
  end

  def project
    @project ||= work_package.project
  end

  def work_package
    @work_package ||= WorkPackage.visible(current_user).find_by(id: params[:id])
  end

  def journals
    @journals ||= work_package.journals.changing
                  .includes(:user)
                  .order("#{Journal.table_name}.created_at ASC").to_a
    @journals.reverse_order if current_user.wants_comments_in_reverse_order?
    @journals
  end

  private

  def load_work_packages
    sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
    sort_update(@query.sortable_key_by_column_name)

    @results = @query.results(order: sort_clause)
    @work_packages = if @query.valid?
                       @results.work_packages.page(page_param)
                       .per_page(per_page_param)
                     else
                       []
                    end
  end

  def login_back_url_params
    params.permit(:query_id, :state, :query_props)
  end
end
