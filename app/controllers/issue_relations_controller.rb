class IssueRelationsController < ApplicationController
  before_filter :find_issue, :find_project_from_association, :authorize
  
  def new
    @relation = IssueRelation.new(params[:relation])
    @relation.issue_from = @issue
    if params[:relation] && m = params[:relation][:issue_to_id].to_s.match(/^#?(\d+)$/)
      @relation.issue_to = Issue.visible.find_by_id(m[1].to_i)
    end
    @relation.save if request.post?
    respond_to do |format|
      format.html { redirect_to :controller => 'issues', :action => 'show', :id => @issue }
      format.js do
        @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
        render :update do |page|
          page.replace_html "relations", :partial => 'issues/relations'
          if @relation.errors.empty?
            page << "$('relation_delay').value = ''"
            page << "$('relation_issue_to_id').value = ''"
          end
        end
      end
    end
  end
  
  def destroy
    relation = IssueRelation.find(params[:id])
    if request.post? && @issue.relations.include?(relation)
      relation.destroy
      @issue.reload
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'issues', :action => 'show', :id => @issue }
      format.js {
        @relations = @issue.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
        render(:update) {|page| page.replace_html "relations", :partial => 'issues/relations'}
      }
    end
  end
  
private
  def find_issue
    @issue = @object = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
