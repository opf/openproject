require 'json'

module Report::Controller
  def self.included(base)
    base.class_eval do
      attr_accessor :report_engine
      helper_method :current_user
      helper_method :allowed_to?

      include ReportingHelper
      helper ReportingHelper
      helper { def engine; @report_engine; end }

      before_filter :determine_engine
      before_filter :prepare_query, :only => [:index, :create]
      before_filter :find_optional_report, :only => [:index, :show, :update, :delete, :rename]
      before_filter :possibly_only_narrow_values

      if Rails.version.start_with? "3"
        before_filter { @no_progress = no_progress? }
      else
        before_filter do |controller|
          controller.instance_eval { @no_progress = controller.no_progress? }
        end
      end
    end
  end

  def index
    table
  end

  ##
  # Render the report. Renders either the complete index or the table only
  def table
    if set_filter? and request.xhr?
      if no_progress?
        table_without_progress_info
      else
        table_with_progress_info
      end
    end
  end

  def table_without_progress_info
    stream do
      render_widget Widget::Table, @query
    end
  end

  def table_with_progress_info
    render :text => render_widget(Widget::Table::Progressbar, @query), :layout => !request.xhr?
  end

  if Rails.version.start_with? "3"
    def stream(&block)
      self.response_body = block
    end
  else
    def stream(&block)
      render :text => block.call, :layout => false
    end
  end

  ##
  # Create a new saved query. Returns the redirect url to an XHR or redirects directly
  def create
    @query.name = params[:query_name].present? ? params[:query_name] : ::I18n.t(:label_default)
    @query.public! if make_query_public?
    @query.send("#{user_key}=", current_user.id)
    @query.save!
    if request.xhr? # Update via AJAX - return url for redirect
      render :text => url_for(:action => "show", :id => @query.id)
    else # Redirect to the new record
      redirect_to :action => "show", :id => @query.id
    end
  end

  ##
  # Show a saved record, if found. Raises RecordNotFound if the specified query
  # at :id does not exist
  def show
    if @query
      store_query(@query)
      table
      render :action => "index" unless performed?
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  ##
  # Delete a saved record, if found. Redirects to index on success, raises a
  # RecordNotFound if the query at :id does not exist
  def delete
    if @query
      @query.destroy if allowed_to? :delete, @query
    else
      raise ActiveRecord::RecordNotFound
    end
    redirect_to :action => "index", :default => 1
  end

  ##
  # Update a record with new query parameters and save it. Redirects to the
  # specified record or renders the updated table on XHR
  def update
    if params[:set_filter].to_i == 1 #save
      old_query = @query
      prepare_query
      old_query.migrate(@query)
      old_query.save!
      @query = old_query
    end
    if request.xhr?
      table
    else
      redirect_to :action => "show", :id => @query.id
    end
  end

  ##
  # Rename a record and update its publicity. Redirects to the updated record or
  # renders the updated name on XHR
  def rename
    @query.name = params[:query_name]
    @query.public! if make_query_public?
    @query.save!
    store_query(@query)
    unless request.xhr?
      redirect_to :action => "show", :id => @query.id
    else
      render :text => @query.name
    end
  end

  ##
  # Determine the available values for the specified filter and return them as
  # json, if that was requested. This will be executed INSTEAD of the actual action
  def possibly_only_narrow_values
    if params[:narrow_values] == "1"
      sources = params[:sources]
      dependent = params[:dependent]

      query = report_engine.new
      sources.each do |dependency|
        query.filter(dependency.to_sym,
          :operator => params[:operators][dependency],
          :values => params[:values][dependency])
      end
      query.column(dependent)
      values = [[::I18n.t(:label_inactive), '<<inactive>>']] + query.result.collect {|r| r.fields[query.group_bys.first.field] }
      # replace null-values with corresponding placeholder
      values = values.map { |value| value.nil? ? [::I18n.t(:label_none), '<<null>>'] : value }
      # try to find corresponding labels to the given values
      values = values.map do |value|
        filter = report_engine::Filter.const_get(dependent.camelcase.to_sym)
        filter_value = filter.label_for_value value
        if filter_value && filter_value.first.is_a?(Symbol)
          [::I18n.t(filter_value.first), filter_value.second]
        elsif filter_value && filter_value.first.is_a?(String)
          [filter_value.first, filter_value.second]
        else
          value
        end
      end
      render :json => values.to_json
    end
  end

  ##
  # Determine the requested engine by constantizing from the :engine parameter
  # Sets @report_engine and @title based on that, and makes the engine available
  # to views and widgets via the #engine method.
  # Raises RecordNotFound on failure
  def determine_engine
    @report_engine = params[:engine].constantize
    @title = "label_#{@report_engine.name.underscore}"
  rescue NameError
    raise ActiveRecord::RecordNotFound, "No engine found - override #determine_engine"
  end

  ##
  # Determines if the request contains filters to set
  def set_filter? #FIXME: rename to set_query?
    params[:set_filter].to_i == 1
  end

  ##
  # Determines if the requested table should be rendered with a progressbar
  def no_progress?
    !!params[:immediately]
  end

  ##
  # Return the active filters
  def filter_params
    filters = http_filter_parameters if set_filter?
    filters ||= session[report_engine.name.underscore.to_sym].try(:[], :filters)
    filters ||= default_filter_parameters
  end

  ##
  # Return the active group bys
  def group_params
    groups = http_group_parameters if set_filter?
    groups ||= session[report_engine.name.underscore.to_sym].try(:[], :groups)
    groups ||= default_group_parameters
  end

  ##
  # Extract active filters from the http params
  def http_filter_parameters
    params[:fields] ||= []
    (params[:fields].reject { |f| f.empty? } || []).inject({:operators => {}, :values => {}}) do |hash, field|
      hash[:operators][field.to_sym] = params[:operators][field]
      hash[:values][field.to_sym] = params[:values][field]
      hash
    end
  end

  ##
  # Extract active group bys from the http params
  def http_group_parameters
    if params[:groups]
      rows = params[:groups]["rows"]
      columns = params[:groups]["columns"]
    end
    {:rows => (rows || []), :columns => (columns || [])}
  end

  ##
  # Set a default query to cut down initial load time
  def default_filter_parameters
    { :operators => {}, :values => {} }
  end

  ##
  # Set a default query to cut down initial load time
  def default_group_parameters
    {:columns => [:sector_id], :rows => [:country_id]}
  end

  ##
  # Determines if the query settings should be reset
  def force_default?
    params[:default].to_i == 1
  end

  ##
  # Prepare the query from the request
  def prepare_query
    determine_settings
    @query = build_query(session[report_engine.name.underscore.to_sym][:filters],
                         session[report_engine.name.underscore.to_sym][:groups])
  end

  ##
  # Determine the query settings the current request and save it to
  # the session.
  def determine_settings
    if force_default?
      filters = default_filter_parameters
      groups  = default_group_parameters
      session[report_engine.name.underscore.to_sym].try :delete, :name
    else
      filters = filter_params
      groups  = group_params
    end
    cookie = session[report_engine.name.underscore.to_sym] || {}
    session[report_engine.name.underscore.to_sym] = cookie.merge({:filters => filters, :groups => groups})
  end

  ##
  # Build the query from the passed session hash
  def build_query(filters, groups = {})
    query = report_engine.new
    query.tap do |q|
      filters[:operators].each do |filter, operator|
        unless filters[:values][filter]==["<<inactive>>"]
          values = filters[:values][filter].map{ |v| v=='<<null>>' ? nil : v }
          q.filter(filter.to_sym,
                   :operator => operator,
                   :values => values )
        end
      end
    end
    groups[:rows].try(:reverse_each) {|r| query.row(r) }
    groups[:columns].try(:reverse_each) {|c| query.column(c) }
    query
  end

  ##
  # Store query in the session
  def store_query(query)
    cookie = {}
    cookie[:groups] = @query.group_bys.inject({}) do |h, group|
      ((h[:"#{group.type}s"] ||= []) << group.underscore_name.to_sym) && h
    end
    cookie[:filters] = @query.filters.inject({:operators => {}, :values => {}}) do |h, filter|
      h[:operators][filter.underscore_name.to_sym] = filter.operator.to_s
      h[:values][filter.underscore_name.to_sym] = filter.values
      h
    end
    cookie[:name] = @query.name if @query.name
    session[report_engine.name.underscore.to_sym] = cookie
  end

  ##
  # Override in subclass if user key
  def user_key
    'user_id'
  end

  ##
  # Override in subclass if you like
  def is_public_sql(val=true)
    "(is_public = #{val ? report_engine.reporting_connection.quoted_true : report_engine.reporting_connection.quoted_false})"
  end

  ##
  # Fallback: @current_user needs to be set for the engine
  def current_user
    if @current_user.nil?
      raise NotImplementedError, "The #{self.class} should have set @current_user before this request"
    end
    @current_user
  end

  ##
  # Abstract: Implementation required in application
  def allowed_to?(action, subject, user = current_user)
    raise NotImplementedError, "The #{self.class} should have implemented #allowed_to?(action, subject, user)"
  end

  def make_query_public?
    !!params[:query_is_public]
  end

  # renders option tags for each available value for a single filter
  def available_values
    if name = params[:filter_name]
      f_cls = report_engine::Filter.const_get(name.to_s.camelcase)
      filter = f_cls.new.tap do |f|
        f.values = JSON.parse(params[:values].gsub("'", '"')) if params[:values].present? and params[:values]
      end
      render_widget Widget::Filters::Option, filter, :to => canvas = ""
      render :text => canvas, :layout => !request.xhr?
    end
  end

  ##
  # Find a report if :id was passed as parameter.
  # Raises RecordNotFound if an invalid :id was passed.
  #
  # @param query An optional query added to the disjunction qualifiying reports to be returned.
  def find_optional_report(query="1=0")
    if params[:id]
      @query = report_engine.find(params[:id].to_i,
        :conditions => ["#{is_public_sql} OR (#{user_key} = ?) OR (#{query})", current_user.id])
      @query.deserialize if @query
    end
  rescue ActiveRecord::RecordNotFound
  end
end

