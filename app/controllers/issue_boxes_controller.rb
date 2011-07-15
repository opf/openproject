class IssueBoxesController < IssuesController
  unloadable

  helper :rb_common

  def show
    return redirect_to issue_path(params[:id]) unless request.xhr?

    @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @changesets = @issue.changesets.visible.all
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?
    @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.all
    @time_entry = TimeEntry.new
    respond_to do |format|
      format.js   { render :partial => 'show' }
    end
  end
  
  def edit
    # return redirect_to edit_issue_path(params[:id]) unless request.xhr?

    @journals = @issue.journals.find(:all, :include => [:user, :details], :order => "#{Journal.table_name}.created_on ASC")
    @journals.each_with_index {|j,i| j.indice = i+1}
    @journals.reverse! if User.current.wants_comments_in_reverse_order?
    @changesets = @issue.changesets.visible.all
    @changesets.reverse! if User.current.wants_comments_in_reverse_order?
    @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @edit_allowed = User.current.allowed_to?(:edit_issues, @project)
    @priorities = IssuePriority.all
    @time_entry = TimeEntry.new
    respond_to do |format|
      format.js   { render :partial => 'edit' }
    end
  end
  
  def update
    update_issue_from_params

    if @issue.save_issue_with_child_records(params, @time_entry)
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?

      respond_to do |format|
        format.html   { render :partial => 'show'}
      end
    else
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record?
      @journal = @issue.current_journal

      respond_to do |format|
        format.html { render :partial => 'edit' }
      end
    end
  end
  
  private
  def update_issue_from_params
    @time_entry = TimeEntry.new
    @time_entry.attributes = params[:time_entry]
    
    @notes = params[:notes] || (params[:issue].present? ? params[:issue][:notes] : nil)
    @issue.init_journal(User.current, @notes)
    @issue.safe_attributes = params[:issue]
  end
end
