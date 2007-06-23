class TimelogController < ApplicationController
  layout 'base'
  
  before_filter :find_project
  before_filter :authorize, :only => :edit
  before_filter :check_project_privacy, :only => :details

  helper :sort
  include SortHelper
  
  def details
    sort_init 'spent_on', 'desc'
    sort_update
    
    @entries = (@issue ? @issue : @project).time_entries.find(:all, :include => [:activity, :user, {:issue => [:tracker, :assigned_to, :priority]}], :order => sort_clause)

    @total_hours = @entries.inject(0) { |sum,entry| sum + entry.hours }
    @owner_id = logged_in_user ? logged_in_user.id : 0
    
    send_csv and return if 'csv' == params[:export]    
    render :action => 'details', :layout => false if request.xhr?
  end
  
  def edit
    render_404 and return if @time_entry && @time_entry.user != logged_in_user
    @time_entry ||= TimeEntry.new(:project => @project, :issue => @issue, :user => logged_in_user, :spent_on => Date.today)
    @time_entry.attributes = params[:time_entry]
    if request.post? and @time_entry.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'details', :project_id => @time_entry.project, :issue_id => @time_entry.issue
      return
    end    
    @activities = Enumeration::get_values('ACTI')
  end

private
  def find_project
    if params[:id]
      @time_entry = TimeEntry.find(params[:id])
      @project = @time_entry.project
    elsif params[:issue_id]
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project
    elsif params[:project_id]
      @project = Project.find(params[:project_id])
    else
      render_404
      return false
    end
  end
  
  def send_csv
    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')    
    export = StringIO.new
    CSV::Writer.generate(export, l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [l(:field_spent_on),
                 l(:field_user),
                 l(:field_activity),
                 l(:field_issue),
                 l(:field_hours),
                 l(:field_comments)
                 ]
      csv << headers.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      # csv lines
      @entries.each do |entry|
        fields = [l_date(entry.spent_on),
                  entry.user.name,
                  entry.activity.name,
                  (entry.issue ? entry.issue.id : nil),
                  entry.hours,
                  entry.comments
                  ]
        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export.rewind
    send_data(export.read, :type => 'text/csv; header=present', :filename => 'export.csv')
  end
end
