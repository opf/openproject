# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class IssueCategoriesController < ApplicationController
  menu_item :settings
  model_object IssueCategory
  before_filter :find_model_object, :except => :new
  before_filter :find_project_from_association, :except => :new
  before_filter :find_project, :only => :new
  before_filter :authorize
  
  verify :method => :post, :only => :destroy

  def new
    @category = @project.issue_categories.build(params[:category])
    if request.post?
      if @category.save
        respond_to do |format|
          format.html do
            flash[:notice] = l(:notice_successful_create)
            redirect_to :controller => 'projects', :action => 'settings', :tab => 'categories', :id => @project
          end
          format.js do
            # IE doesn't support the replace_html rjs method for select box options
            render(:update) {|page| page.replace "issue_category_id",
              content_tag('select', '<option></option>' + options_from_collection_for_select(@project.issue_categories, 'id', 'name', @category.id), :id => 'issue_category_id', :name => 'issue[category_id]')
            }
          end
        end
      else
        respond_to do |format|
          format.html
          format.js do
            render(:update) {|page| page.alert(@category.errors.full_messages.join('\n')) }
          end
        end
      end
    end
  end
  
  def edit
    if request.post? and @category.update_attributes(params[:category])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :controller => 'projects', :action => 'settings', :tab => 'categories', :id => @project
    end
  end

  def destroy
    @issue_count = @category.issues.size
    if @issue_count == 0
      # No issue assigned to this category
      @category.destroy
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'categories'
      return
    elsif params[:todo]
      reassign_to = @project.issue_categories.find_by_id(params[:reassign_to_id]) if params[:todo] == 'reassign'
      @category.destroy(reassign_to)
      redirect_to :controller => 'projects', :action => 'settings', :id => @project, :tab => 'categories'
      return
    end
    @categories = @project.issue_categories - [@category]
  end

private
  # Wrap ApplicationController's find_model_object method to set
  # @category instead of just @issue_category
  def find_model_object
    super
    @category = @object
  end    
  
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
