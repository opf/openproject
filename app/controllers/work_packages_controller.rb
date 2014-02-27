#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

  menu_item :new_work_package, :only => [:new, :create]

  current_menu_item :index do |controller|
    query = controller.instance_variable_get :"@query"

    if query && query.persisted? && current = query.query_menu_item.try(:name)
      current.to_sym
    else
      :work_packages
    end
  end

  include QueriesHelper
  include SortHelper
  include PaginationHelper

  accept_key_auth :index, :show, :create, :update

  # before_filter :disable_api # TODO re-enable once API is used for any JSON request
  before_filter :not_found_unless_work_package,
                :project,
                :authorize, :except => [:index, :column_data, :column_sums]
  before_filter :find_optional_project,
                :protect_from_unauthorized_export, :only => [:index, :all]
  before_filter :load_query, :only => :index

  def show
    respond_to do |format|
      format.html do
        render :show, :locals => { :work_package => work_package,
                                   :project => project,
                                   :priorities => priorities,
                                   :user => current_user,
                                   :ancestors => ancestors,
                                   :descendants => descendants,
                                   :changesets => changesets,
                                   :relations => relations,
                                   :journals => journals }
      end

      format.js do
        render :show, :partial => 'show', :locals => { :work_package => work_package,
                                                       :project => project,
                                                       :priorities => priorities,
                                                       :user => current_user,
                                                       :ancestors => ancestors,
                                                       :descendants => descendants,
                                                       :changesets => changesets,
                                                       :relations => relations,
                                                       :journals => journals }
      end

      format.pdf do
        pdf = WorkPackage::Exporter.work_package_to_pdf(work_package)

        send_data(pdf,
                  :type => 'application/pdf',
                  :filename => "#{project.identifier}-#{work_package.id}.pdf")
      end

      format.atom do
        render :template => 'journals/index',
               :layout => false,
               :content_type => 'application/atom+xml',
               :locals => { :title => "#{Setting.app_title} - #{work_package.to_s}",
                            :journals => journals }
      end
    end
  end

  def new
    respond_to do |format|
      format.html { render :locals => { :work_package => work_package,
                                        :project => project,
                                        :priorities => priorities,
                                        :user => current_user } }
    end
  end

  def new_type
    safe_params = permitted_params.update_work_package(:project => project)
    work_package.update_by(current_user, safe_params)

    respond_to do |format|
      format.js { render :locals => { :work_package => work_package,
                                      :project => project,
                                      :priorities => priorities,
                                      :user => current_user } }
    end
  end

  def preview
    safe_params = permitted_params.update_work_package(project: project)
    work_package.update_by(current_user, safe_params)

    respond_to do |format|
      format.any(:html, :js) { render 'preview', locals: { work_package: work_package },
                                                 layout: false }
    end
  end

  def create
    call_hook(:controller_work_package_new_before_save, { :params => params, :work_package => work_package })

    WorkPackageObserver.instance.send_notification = send_notifications?

    work_package.attach_files(params[:attachments])

    if work_package.save
      flash[:notice] = I18n.t(:notice_successful_create)

      call_hook(:controller_work_package_new_after_save, { :params => params, :work_package => work_package })

      redirect_to(work_package_path(work_package))
    else
      respond_to do |format|
        format.html { render :action => 'new', :locals => { :work_package => work_package,
                                                            :project => project,
                                                            :priorities => priorities,
                                                            :user => current_user } }
      end
    end
  end

  def edit
    locals =   { :work_package => work_package,
                 :allowed_statuses => allowed_statuses,
                 :project => project,
                 :priorities => priorities,
                 :time_entry => time_entry,
                 :user => current_user }

    respond_to do |format|
      format.html do
        render :edit, :locals => locals
      end
      format.js do
        render :partial => "edit", :locals => locals
      end
    end
  end

  def update
    configure_update_notification(send_notifications?)

    safe_params = permitted_params.update_work_package(:project => project)
    updated = work_package.update_by!(current_user, safe_params)

    render_attachment_warning_if_needed(work_package)

    if updated

      flash[:notice] = l(:notice_successful_update)

      show
    else
      edit
    end
  rescue ActiveRecord::StaleObjectError
    error_message = l(:notice_locking_conflict)
    render_attachment_warning_if_needed(work_package)

    journals_since = work_package.journals.after(work_package.lock_version)
    if journals_since.any?
      changes = journals_since.map { |j| "#{j.user.name} (#{j.created_at.to_s(:short)})" }
      error_message << " " << l(:notice_locking_conflict_additional_information, :users => changes.join(', '))
    end

    error_message << " " << l(:notice_locking_conflict_reload_page)

    work_package.errors.add :base, error_message

    edit
  end

  def index
    sort_init(@query.sort_criteria.empty? ? [DEFAULT_SORT_ORDER] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    results = @query.results(:include => [:assigned_to, :type, :priority, :category, :fixed_version],
                            :order => sort_clause)

    work_packages = if @query.valid?
                      results.work_packages.page(page_param)
                                           .per_page(per_page_param)
                                           .all
                    else
                      []
                    end


    respond_to do |format|
      format.html do
        # push work packages to client as JSON
        # TODO pull work packages via AJAX
        push_filter_operators_and_labels
        push_query_and_results_via_gon results, work_packages

        render :index, :locals => { :query => @query,
                                    :work_packages => work_packages,
                                    :results => results,
                                    :project => @project },
                       :layout => !request.xhr?
      end
      format.json do
        render json: get_results_as_json(results, work_packages)
      end
      format.csv do
        serialized_work_packages = WorkPackage::Exporter.csv(work_packages, @project)
        charset = "charset=#{l(:general_csv_encoding).downcase}"

        send_data(serialized_work_packages, :type => "text/csv; #{charset}; header=present",
                                            :filename => 'export.csv')
      end
      format.pdf do
        serialized_work_packages = WorkPackage::Exporter.pdf(work_packages,
                                                             @project,
                                                             @query,
                                                             results,
                                                             :show_descriptions => params[:show_descriptions])

        send_data(serialized_work_packages,
                  :type => 'application/pdf',
                  :filename => 'export.pdf')
      end
      format.atom do
        render_feed(work_packages,
                    :title => "#{@project || Setting.app_title}: #{l(:label_work_package_plural)}")
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # ------------------- Custom API method -------------------
  # TODO Move to API
  def column_data
    raise 'API Error' unless params[:ids] && params[:column_names]

    column_names = params[:column_names]
    ids = params[:ids].map(&:to_i)
    work_packages = Array.wrap(WorkPackage.visible.find(*ids)).sort {|a,b| ids.index(a.id) <=> ids.index(b.id)}

    render json: fetch_columns_data(column_names, work_packages)
  end

  def column_sums
    # TODO RS: Needs to work for groups, what's the deal?
    raise 'API Error' unless params[:column_names]

    column_names = params[:column_names]
    project = Project.find_visible(current_user, params[:id])
    work_packages = project.work_packages

    sums = column_names.map do |column_name|
      column_is_numeric?(column_name) ? fetch_column_data(column_name, work_packages).map{|c| c.nil? ? 0 : c}.sum : nil
    end

    render json: sums
  end

  def fetch_columns_data(column_names, work_packages)
    columns = column_names.map do |column_name|
      fetch_column_data(column_name, work_packages)
    end
  end

  def fetch_column_data(column_name, work_packages)
    column = if column_name =~ /cf_(.*)/
        work_packages.map do |work_package|
          value = work_package.custom_values.find_by_custom_field_id($1) and value.nil? ? {} : value.attributes
        end
      else
        work_packages.map do |work_package|
          # Note: Doing as_json here because if we just take the value.attributes then we can't get any methods later.
          #       Name and subject are the default properties that the front end currently looks for to summarize an object.
          value = work_package.send(column_name) and value.is_a?(ActiveRecord::Base) ? value.as_json( only: "id", methods: [:name, :subject] ) : value
        end
      end
  end

  def column_is_numeric?(column_name)
    # TODO RS: We want to leave out ids even though they are numeric
    [:integer, :float].include? column_type(column_name)
  end

  def column_type(column_name)
    column_name =~ /cf_(.*)/ ? CustomField.find($1).field_format.to_sym : (c = WorkPackage.columns_hash[column_name] and c.nil? ? :none : c.type)
  end


  # ---------------------------------------------------------


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

    locals = { :work_package => work_package,
               :allowed_statuses => allowed_statuses,
               :project => project,
               :priorities => priorities,
               :time_entry => time_entry,
               :user => current_user }

    respond_to do |format|
      format.js { render :partial => 'edit', locals: locals }
      format.html { render :action => 'edit', locals: locals }
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
                    permitted_params.new_work_package(:project => project)
                  else
                    params[:work_package] ||= {}
                    {}
                  end

      permitted[:author] = current_user

      wp = project.add_work_package(permitted)
      wp.copy_from(params[:copy_from], :exclude => [:project_id]) if params[:copy_from]

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
                                       .includes({ :repository => {:project => :enabled_modules} }, :user)
                                       .all

      changes.reverse! if current_user.wants_comments_in_reverse_order?

      changes
    end
  end

  def relations
    @relations ||= work_package.relations.includes(:from => [:status,
                                                                   :priority,
                                                                   :type,
                                                                   { :project => :enabled_modules }],
                                                   :to => [:status,
                                                                 :priority,
                                                                 :type,
                                                                 { :project => :enabled_modules }])
                                         .select{ |r| r.other_work_package(work_package) && r.other_work_package(work_package).visible? }
  end

  def priorities
    IssuePriority.all
  end

  def allowed_statuses
    work_package.new_statuses_allowed_to(current_user)
  end

  def time_entry
    attributes = {}
    permitted = {}

    if params[:work_package]
      permitted = permitted_params.update_work_package(:project => project)
    end

    if permitted.has_key?("time_entry")
      attributes = permitted["time_entry"]
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
      !User.current.allowed_to?(:export_work_packages, @project, :global => @project.nil?)

      deny_access
      false
    end
  end

  def configure_update_notification(state = true)
    JournalObserver.instance.send_notification = state
  end

  def send_notifications?
    params[:send_notification] == '0' ? false : true
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

  # ------------------- Form JSON reponse for angular -------------------
  # TODO provide data in API

  def push_filter_operators_and_labels
    gon.operators_and_labels_by_filter_type = get_operators_and_labels_by_filter_type

  end

  def push_query_and_results_via_gon(results, work_packages)
    get_query_and_results_as_json(results, work_packages).each_pair do |name, value|
      # binding.pry if name == :query
      gon.send "#{name}=", value
    end
    # TODO later versions of gon support gon.push {Hash} - on the other hand they make it harder to deliver data to gon inside views
  end

  # filter information

  def get_operators_and_labels_by_filter_type
    Queries::Filter.operators_by_filter_type.inject({}) do |hash, (type, operators)|
      hash.merge type => get_operators_to_label_hash(operators)
    end
  end

  def get_operators_to_label_hash(operators)
    operators.inject({}) do |operators_with_labels, operator|
      operators_with_labels.merge(operator => I18n.t(Queries::Filter.operators[operator]))
    end
  end

  # query

  def get_query_and_results_as_json(results, work_packages)
    get_results_as_json(results, work_packages).merge(
      project_identifier:           @project.to_param,
      query:                        get_query_as_json(@query),
      columns:                      get_columns_for_json(@query.columns),
      available_columns:            get_columns_for_json(@query.available_columns),
      sort_criteria:                @sort_criteria.to_param,
      page:                         page_param,
      per_page:                     per_page_param
    )
  end

  def get_results_as_json(results, work_packages)
    {
      work_package_count_by_group:  results.work_package_count_by_group,
      work_packages:                get_work_packages_as_json(work_packages, @query.columns),
      sums:                         @query.columns.map { |column| results.total_sum_of(column) },
      group_sums:                   @query.group_by_column && @query.columns.map { |column| results.grouped_sums(column) },
      page:                         page_param,
      per_page:                     per_page_param
    }
  end

  def get_query_as_json(query)
    query.as_json only: [:id, :group_by, :display_sums],
                  methods: [:available_work_package_filters]
  end

  def get_columns_for_json(columns)
    columns.map do |column|
      { name: column.name,
        title: column.caption,
        sortable: column.sortable,
        groupable: column.groupable,
        custom_field: column.is_a?(QueryCustomFieldColumn) &&
                      column.custom_field.as_json(only: [:id, :field_format]),
        meta_data: get_column_meta(column)
      }
    end
  end

  def get_column_meta(column)
    # This is where we want to add column specific behaviour to instruct the front end how to deal with it
    # Needs to be things like user link,project link, datetime
    {
      data_type: column_data_type(column),
      link: !!(link_meta()[column.name]) ? link_meta()[column.name] : { display: false }
    }
  end

  def link_meta
    {
      subject: { display: true, model_type: "work_package" },
      type: { display: false },
      status: { display: false },
      priority: { display: false },
      parent: { display: true, model_type: "user" },
      assigned_to: { display: true, model_type: "user" },
      responsible: { display: true, model_type: "user" },
      author: { display: true, model_type: "user" },
      project: { display: true, model_type: "project" }
    }
  end

  def column_data_type(column)
    if column.is_a?(QueryCustomFieldColumn)
      return column.custom_field.field_format
    elsif (c = WorkPackage.columns_hash[column.name.to_s] and !c.nil?)
      return c.type.to_s
    elsif (c = WorkPackage.columns_hash[column.name.to_s + "_id"] and !c.nil?)
      return "object"
    else
      return "default"
    end
  end

  # work packages

  def get_work_packages_as_json(work_packages, selected_columns=[])
    attributes_to_be_displayed = default_work_package_attributes +
                                 (WorkPackage.attribute_names.map(&:to_sym) & selected_columns.map(&:name))

    work_packages.as_json only: attributes_to_be_displayed,
                          methods: [:leaf?, :overdue?],
                          include: get_column_includes(selected_columns)
  end

  def get_column_includes(selected_columns=[])
    selected_associations = {
      assigned_to: { only: :id, methods: :name },
      author: { only: :id, methods: :name },
      category: { only: :name },
      priority: { only: :name },
      project: { only: [:name, :identifier] },
      responsible: { only: :id, methods: :name },
      status: { only: :name },
      type: { only: :name },
      parent: { only: :subject }
    }.slice(*selected_columns.map(&:name))

    selected_associations.merge!(custom_values: { only: [:custom_field_id, :value] }) if selected_columns.any? {|c| c.is_a? QueryCustomFieldColumn}

    # TODO retrieve custom values in a single query like this and extend the work_packages inside the JSON:
    # WorkPackage.includes(:custom_values).where(['work_packages.id in (?) AND custom_values.custom_field_id in (?)', @query.results.map(&:id), custom_field_columns.map(&:id)])

    selected_associations
  end

  def default_work_package_attributes
    %i(id parent_id)
  end
end
