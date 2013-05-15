module Menus
  module Issues
    module Show
      Redmine::MenuManager.map :issues_show do |menu|
        menu.push :edit, { :controller => '/issues',
                           :action => 'edit',
                           :id => @issue }
#        menu.push :my_page, { :controller => '/my', :action => 'page' }, :if => Proc.new { User.current.logged? }
#        # projects menu will be added by Redmine::MenuManager::TopMenuHelper#render_projects_top_menu_node
#        menu.push :administration, { :controller => '/admin', :action => 'projects' }, :if => Proc.new { User.current.admin? }, :last => true
#        menu.push :help, Redmine::Info.help_url, :last => true, :caption => "?", :html => { :accesskey => Redmine::AccessKeys.key_for(:help) }
      end

    end
  end
end
