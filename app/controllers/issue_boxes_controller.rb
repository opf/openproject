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
end
