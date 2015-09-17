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
  unloadable

  DEFAULT_SORT_ORDER = ['parent', 'desc']
  EXPORT_FORMATS = %w[atom rss xls csv pdf]

  menu_item :new_work_package, only: [:new, :create]

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
        render :show, locals: { work_package: work_package,
                                project: project,
                                priorities: priorities,
                                user: current_user,
                                ancestors: ancestors,
                                descendants: descendants,
                                changesets: changesets,
                                relations: relations,
                                journals: journals }
      end

      format.js do
        render :show, partial: 'show', locals: { work_package: work_package,
                                                 project: project,
                                                 priorities: priorities,
                                                 user: current_user,
                                                 ancestors: ancestors,
                                                 descendants: descendants,
                                                 changesets: changesets,
                                                 relations: relations,
                                                 journals: journals }
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

  def new
    respond_to do |format|
      format.html {
        render locals: { work_package: work_package,
                         project: project,
                         priorities: priorities,
                         user: current_user }
      }
    end
  end

  def new_type
    safe_params = permitted_params.update_work_package(project: project)
    work_package.update_by(current_user, safe_params)

    respond_to do |format|
      format.js {
        render locals: { work_package: work_package,
                         project: project,
                         priorities: priorities,
                         user: current_user }
      }
    end
  end

  def create
    call_hook(:controller_work_package_new_before_save,  params: params, work_package: work_package)

    WorkPackageObserver.instance.send_notification = send_notifications?

    work_package.attach_files(params[:attachments])

    if work_package.save
      flash[:notice] = I18n.t(:notice_successful_create)

      call_hook(:controller_work_package_new_after_save,  params: params, work_package: work_package)

      redirect_to(work_package_path(work_package))
    else
      respond_to do |format|
        format.html {
          render action: 'new', locals: { work_package: work_package,
                                          project: project,
                                          priorities: priorities,
                                          user: current_user }
        }
      end
    end
  end

  def edit
    locals =   { work_package: work_package,
                 allowed_statuses: allowed_statuses,
                 project: project,
                 priorities: priorities,
                 time_entry: time_entry,
                 user: current_user,
                 back_url: params[:back_url] }

    respond_to do |format|
      format.html do
        render :edit, locals: locals
      end
      format.js do
        render partial: 'edit', locals: locals
      end
    end
  end

  def update
    safe_params = permitted_params.update_work_package(project: project)

    update_service = UpdateWorkPackageService.new(
      user: current_user,
      work_package: work_package,
      permitted_params: safe_params,
      send_notifications: send_notifications?)

    updated = update_service.update

    render_attachment_warning_if_needed(work_package)

    if updated

      flash[:notice] = l(:notice_successful_update)

      redirect_back_or_default(work_package_path(work_package), false)
    else
      edit
    end
  rescue ActiveRecord::StaleObjectError
    error_message = l(:notice_locking_conflict)
    render_attachment_warning_if_needed(work_package)

    journals_since = work_package.journals.after(work_package.lock_version)
    if journals_since.any?
      changes = journals_since.map { |j| "#{j.user.name} (#{j.created_at.to_s(:short)})" }
      error_message << ' ' << l(:notice_locking_conflict_additional_information, users: changes.join(', '))
    end

    error_message << ' ' << l(:notice_locking_conflict_reload_page)

    work_package.errors.add :base, error_message

    edit
  end

  def index
    load_work_packages unless request.format.html?

    respond_to do |format|
      format.html do
        gon.settings = client_preferences
        gon.settings[:enabled_modules] = @project ? @project.enabled_modules.collect(&:name) : []

        render :index, locals: { query: @query,
                                 project: @project },
                       layout: 'angular' # !request.xhr?
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

  def quoted
    text, author = if params[:journal_id]
                     journal = work_package.journals.find(params[:journal_id])

                     [journal.notes, journal.user]
                   else

                     [work_package.description, work_package.author]
                   end

    work_package.journal_notes = "#{ll(Setting.default_language, :text_user_wrote, author)}\n> "

    text = text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]')
    work_package.journal_notes << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"

    locals = { work_package: work_package,
               allowed_statuses: allowed_statuses,
               project: project,
               priorities: priorities,
               time_entry: time_entry,
               user: current_user }

    respond_to do |format|
      format.js { render partial: 'edit', locals: locals }
      format.html { render action: 'edit', locals: locals }
    end
  end

  def work_package
    if params[:id]
      existing_work_package
    elsif params[:project_id]
      new_work_package
    end
  end

  def existing_work_package
    @existing_work_package ||= begin

      wp = WorkPackage.includes(:project)
           .find_by_id(params[:id])

      wp && wp.visible?(current_user) ?
        wp :
        nil
    end
  end

  def new_work_package
    @new_work_package ||= begin
      project = Project.find_visible(current_user, params[:project_id])
      return nil unless project

      permitted = if params[:work_package]
                    permitted_params.new_work_package(project: project)
                  else
                    params[:work_package] ||= {}
                    {}
                  end

      permitted[:author] = current_user

      wp = project.add_work_package(permitted)
      wp.copy_from(params[:copy_from], exclude: [:project_id]) if params[:copy_from]

      wp
    end
  end

  def project
    @project ||= work_package.project
  end

  def journals
    @journals ||= work_package.journals.changing
                  .includes(:user)
                  .order("#{Journal.table_name}.created_at ASC")
    @journals.reverse! if current_user.wants_comments_in_reverse_order?
    @journals
  end

  def ancestors
    @ancestors ||= work_package.ancestors.visible.includes(:type,
                                                           :assigned_to,
                                                           :status,
                                                           :priority,
                                                           :fixed_version,
                                                           :project)
  end

  def descendants
    @descendants ||= work_package.descendants.visible.includes(:type,
                                                               :assigned_to,
                                                               :status,
                                                               :priority,
                                                               :fixed_version,
                                                               :project)
  end

  def changesets
    @changesets ||= begin
      changes = work_package.changesets.visible
                .includes({ repository: { project: :enabled_modules } }, :user)
                .all

      changes.reverse! if current_user.wants_comments_in_reverse_order?

      changes
    end
  end

  def relations
    @relations ||= work_package.relations.includes(from: [:status,
                                                          :priority,
                                                          :type,
                                                          { project: :enabled_modules }],
                                                   to: [:status,
                                                        :priority,
                                                        :type,
                                                        { project: :enabled_modules }])
                   .select { |r| r.other_work_package(work_package) && r.other_work_package(work_package).visible? }
  end

  def priorities
    priorities = IssuePriority.active
    augment_priorities_with_current_work_package_priority priorities

    priorities
  end

  def augment_priorities_with_current_work_package_priority(priorities)
    current_priority = work_package.try :priority

    priorities << current_priority if current_priority && !priorities.include?(current_priority)
  end

  def allowed_statuses
    work_package.new_statuses_allowed_to(current_user)
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

  protected

  def load_query
    @query ||= retrieve_query
  rescue ActiveRecord::RecordNotFound
    render_404
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

    @results = @query.results(include: [:assigned_to, :type, :priority, :category, :fixed_version],
                              order: sort_clause)
    @work_packages = if @query.valid?
                       @results.work_packages.page(page_param)
                       .per_page(per_page_param)
                       .all
                     else
                       []
                    end
  end

  def parse_preview_data
    parse_preview_data_helper :work_package, [:journal_notes, :description]
  end
end
