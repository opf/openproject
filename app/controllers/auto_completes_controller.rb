class AutoCompletesController < ApplicationController
  before_filter :find_project
  
  def issues
    @issues = []
    q = params[:q].to_s
    query = (params[:scope] == "all" && Setting.cross_project_issue_relations?) ? Issue : @project.issues
    if q.match(/^\d+$/)
      @issues << query.visible.find_by_id(q.to_i)
    end
    unless q.blank?
      @issues += query.visible.find(:all, :conditions => ["LOWER(#{Issue.table_name}.subject) LIKE ?", "%#{q.downcase}%"], :limit => 10)
    end
    render :layout => false
  end

  private

  def find_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
