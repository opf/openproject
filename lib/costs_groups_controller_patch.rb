require_dependency 'groups_controller'

module CostsGroupsControllerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    
    base.class_eval do
      unloadable
      
      alias_method_chain :add_users, :membership_type
    end
  end
  
  module InstanceMethods
    def add_users_with_membership_type
      @group = Group.find(params[:id])
      users = User.find_all_by_id(params[:user_ids])

      # following three lines added/changed to original function
      membership_type = params[:membership_type] || "default"
      groups_users = users.each do |u|
        @group.groups_users.create!(:user_id => u.id, :membership_type => membership_type)
      end

      respond_to do |format|
        format.html { redirect_to :controller => 'groups', :action => 'edit', :id => @group, :tab => 'users' }
        format.js { 
          render(:update) {|page| 
            page.replace_html "tab-content-users", :partial => 'groups/users'
            users.each {|user| page.visual_effect(:highlight, "user-#{user.id}") }
          }
        }
      end
    end
    
    def set_membership_type
      @group = Group.find(params[:id])
      user = User.find(params[:user_id])
      
      membership_type = params[:group_user][:membership_type]
      @group.change_membership_type(user, membership_type)
      
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    end
  end
end

GroupsController.send(:include, CostsGroupsControllerPatch)