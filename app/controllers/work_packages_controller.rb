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

class WorkPackagesController < ApplicationController
  DEFAULT_SORT_ORDER = ['parent', 'desc']
  EXPORT_FORMATS = %w[atom rss xls csv pdf]

  current_menu_item :index do |controller|
    query = controller.instance_variable_get :"@query"

    if query && query.persisted? && current = query.query_menu_item.try(:unique_name)
      current
    else
      :work_packages
    end
  end

  include QueriesHelper
  include PaginationHelper
  include SortHelper
  include OpenProject::Concerns::Preview
  include OpenProject::ClientPreferenceExtractor

  accept_key_auth :index, :show, :create, :update

  # before_filter :disable_api # TODO re-enable once API is used for any JSON request
  before_filter :not_found_unless_work_package,
                :project,
                :authorize, except: [:index, :preview, :column_data, :column_sums]
  before_filter :find_optional_project,
                :protect_from_unauthorized_export, only: [:index, :all, :preview]
  before_filter :load_query, only: :index

  def show
    respond_to do |format|
      format.html do
        gon.settings = client_preferences
        gon.settings[:enabled_modules] = @project ? @project.enabled_modules.collect(&:name) : []

        render :show, locals: { work_package: work_package }, layout: 'angular'
      end

      format.pdf do
        pdf = WorkPackage::Exporter.work_package_to_pdf(work_package)

        send_data(pdf,
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

  def journals
    @journals ||= work_package.journals.changing
                  .includes(:user)
                  .order("#{Journal.table_name}.created_at ASC").to_a
    @journals.reverse_order if current_user.wants_comments_in_reverse_order?
    @journals
  end

  def index
    load_work_packages unless request.format.html?

    respond_to do |format|
      format.html do
        gon.settings = client_preferences
        gon.settings[:enabled_modules] = @project ? @project.enabled_modules.collect(&:name) : []

        render :index, locals: { query: @query, project: @project },
                       layout: 'angular'
      end

      format.csv do
        serialized_work_packages = WorkPackage::Exporter.csv(@work_packages, @query)
        charset = "charset=#{l(:general_csv_encoding).downcase}"
        title = @query.new_record? ? l(:label_work_package_plural) : @query.name

        send_data(serialized_work_packages, type: "text/csv; #{charset}; header=present",
                                            filename: "#{title}.csv")
      end

      format.pdf do
        serialized_work_packages = WorkPackage::Exporter.pdf(@work_packages,
                                                             @project,
                                                             @query,
                                                             @results,
                                                             show_descriptions: params[:show_descriptions])

        send_data(serialized_work_packages,
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
  end

  def project
    @project ||= work_package.project
  end

  def time_entry
    attributes = {}
    permitted = {}

    if params[:work_package]
      permitted = permitted_params.update_work_package(project: project)
    end

    if permitted.has_key?('time_entry')
      attributes = permitted['time_entry']
    end

    work_package.add_time_entry(attributes)
  end

  def work_package
    if params[:id]
      existing_work_package
    end
  end

  protected

  def load_query
    @query ||= retrieve_query
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def existing_work_package
    @existing_work_package ||= begin
      wp = WorkPackage.includes(:project).find_by(id: params[:id])
      wp && wp.visible?(current_user) ? wp : nil
    end
  end

  def not_found_unless_work_package
    render_404 unless work_package
  end

  def protect_from_unauthorized_export
    if EXPORT_FORMATS.include?(params[:format]) &&
       !User.current.allowed_to?(:export_work_packages, @project, global: @project.nil?)

      deny_access
      false
    end
  end

  def send_notifications?
    params[:send_notification] != '0'
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

  private

  def load_work_packages
    sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    @results = @query.results(order: sort_clause)
    @work_packages = if @query.valid?
                       @results.work_packages.page(page_param)
                       .per_page(per_page_param)
                     else
                       []
                    end
  end
end
