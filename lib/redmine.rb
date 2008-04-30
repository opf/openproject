require 'redmine/access_control'
require 'redmine/menu_manager'
require 'redmine/mime_type'
require 'redmine/core_ext'
require 'redmine/themes'
require 'redmine/plugin'

begin
  require_library_or_gem 'RMagick' unless Object.const_defined?(:Magick)
rescue LoadError
  # RMagick is not available
end

REDMINE_SUPPORTED_SCM = %w( Subversion Darcs Mercurial Cvs Bazaar Git )

# Permissions
Redmine::AccessControl.map do |map|
  map.permission :view_project, {:projects => [:show, :activity]}, :public => true
  map.permission :search_project, {:search => :index}, :public => true
  map.permission :edit_project, {:projects => [:settings, :edit]}, :require => :member
  map.permission :select_project_modules, {:projects => :modules}, :require => :member
  map.permission :manage_members, {:projects => :settings, :members => [:new, :edit, :destroy]}, :require => :member
  map.permission :manage_versions, {:projects => [:settings, :add_version], :versions => [:edit, :destroy]}, :require => :member
  
  map.project_module :issue_tracking do |map|
    # Issue categories
    map.permission :manage_categories, {:projects => [:settings, :add_issue_category], :issue_categories => [:edit, :destroy]}, :require => :member
    # Issues
    map.permission :view_issues, {:projects => [:changelog, :roadmap], 
                                  :issues => [:index, :changes, :show, :context_menu],
                                  :versions => [:show, :status_by],
                                  :queries => :index,
                                  :reports => :issue_report}, :public => true                    
    map.permission :add_issues, {:issues => :new}
    map.permission :edit_issues, {:issues => [:edit, :bulk_edit, :destroy_attachment]}
    map.permission :manage_issue_relations, {:issue_relations => [:new, :destroy]}
    map.permission :add_issue_notes, {:issues => :edit}
    map.permission :edit_issue_notes, {:journals => :edit}, :require => :loggedin
    map.permission :edit_own_issue_notes, {:journals => :edit}, :require => :loggedin
    map.permission :move_issues, {:issues => :move}, :require => :loggedin
    map.permission :delete_issues, {:issues => :destroy}, :require => :member
    # Queries
    map.permission :manage_public_queries, {:queries => [:new, :edit, :destroy]}, :require => :member
    map.permission :save_queries, {:queries => [:new, :edit, :destroy]}, :require => :loggedin
    # Gantt & calendar
    map.permission :view_gantt, :projects => :gantt
    map.permission :view_calendar, :projects => :calendar
  end
  
  map.project_module :time_tracking do |map|
    map.permission :log_time, {:timelog => :edit}, :require => :loggedin
    map.permission :view_time_entries, :timelog => [:details, :report]
    map.permission :edit_time_entries, {:timelog => [:edit, :destroy]}, :require => :member
    map.permission :edit_own_time_entries, {:timelog => [:edit, :destroy]}, :require => :loggedin
  end
  
  map.project_module :news do |map|
    map.permission :manage_news, {:news => [:new, :edit, :destroy, :destroy_comment]}, :require => :member
    map.permission :view_news, {:news => [:index, :show]}, :public => true
    map.permission :comment_news, {:news => :add_comment}
  end

  map.project_module :documents do |map|
    map.permission :manage_documents, {:documents => [:new, :edit, :destroy, :add_attachment, :destroy_attachment]}, :require => :loggedin
    map.permission :view_documents, :documents => [:index, :show, :download]
  end
  
  map.project_module :files do |map|
    map.permission :manage_files, {:projects => :add_file, :versions => :destroy_file}, :require => :loggedin
    map.permission :view_files, :projects => :list_files, :versions => :download
  end
    
  map.project_module :wiki do |map|
    map.permission :manage_wiki, {:wikis => [:edit, :destroy]}, :require => :member
    map.permission :rename_wiki_pages, {:wiki => :rename}, :require => :member
    map.permission :delete_wiki_pages, {:wiki => :destroy}, :require => :member
    map.permission :view_wiki_pages, :wiki => [:index, :history, :diff, :annotate, :special]
    map.permission :edit_wiki_pages, :wiki => [:edit, :preview, :add_attachment, :destroy_attachment]
  end
    
  map.project_module :repository do |map|
    map.permission :manage_repository, {:repositories => [:edit, :destroy]}, :require => :member
    map.permission :browse_repository, :repositories => [:show, :browse, :entry, :annotate, :changes, :diff, :stats, :graph]
    map.permission :view_changesets, :repositories => [:show, :revisions, :revision]
  end

  map.project_module :boards do |map|
    map.permission :manage_boards, {:boards => [:new, :edit, :destroy]}, :require => :member
    map.permission :view_messages, {:boards => [:index, :show], :messages => [:show]}, :public => true
    map.permission :add_messages, {:messages => [:new, :reply]}
    map.permission :edit_messages, {:messages => :edit}, :require => :member
    map.permission :delete_messages, {:messages => :destroy}, :require => :member
  end
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push :home, :home_path, :html => { :class => 'home' }
  menu.push :my_page, { :controller => 'my', :action => 'page' }, :html => { :class => 'mypage' }, :if => Proc.new { User.current.logged? }
  menu.push :projects, { :controller => 'projects', :action => 'index' }, :caption => :label_project_plural, :html => { :class => 'projects' }
  menu.push :administration, { :controller => 'admin', :action => 'index' }, :html => { :class => 'admin' }, :if => Proc.new { User.current.admin? }
  menu.push :help, Redmine::Info.help_url, :html => { :class => 'help' }
end

Redmine::MenuManager.map :account_menu do |menu|
  menu.push :login, :signin_path, :html => { :class => 'login' }, :if => Proc.new { !User.current.logged? }
  menu.push :register, { :controller => 'account', :action => 'register' }, :html => { :class => 'register' }, :if => Proc.new { !User.current.logged? && Setting.self_registration? }
  menu.push :my_account, { :controller => 'my', :action => 'account' }, :html => { :class => 'myaccount' }, :if => Proc.new { User.current.logged? }
  menu.push :logout, :signout_path, :html => { :class => 'logout' }, :if => Proc.new { User.current.logged? }
end

Redmine::MenuManager.map :application_menu do |menu|
  # Empty
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push :overview, { :controller => 'projects', :action => 'show' }
  menu.push :activity, { :controller => 'projects', :action => 'activity' }
  menu.push :roadmap, { :controller => 'projects', :action => 'roadmap' }, 
              :if => Proc.new { |p| p.versions.any? }
  menu.push :issues, { :controller => 'issues', :action => 'index' }, :param => :project_id, :caption => :label_issue_plural
  menu.push :new_issue, { :controller => 'issues', :action => 'new' }, :param => :project_id, :caption => :label_issue_new,
              :html => { :accesskey => Redmine::AccessKeys.key_for(:new_issue) }
  menu.push :news, { :controller => 'news', :action => 'index' }, :param => :project_id, :caption => :label_news_plural
  menu.push :documents, { :controller => 'documents', :action => 'index' }, :param => :project_id, :caption => :label_document_plural
  menu.push :wiki, { :controller => 'wiki', :action => 'index', :page => nil }, 
              :if => Proc.new { |p| p.wiki && !p.wiki.new_record? }
  menu.push :boards, { :controller => 'boards', :action => 'index', :id => nil }, :param => :project_id,
              :if => Proc.new { |p| p.boards.any? }, :caption => :label_board_plural
  menu.push :files, { :controller => 'projects', :action => 'list_files' }, :caption => :label_attachment_plural
  menu.push :repository, { :controller => 'repositories', :action => 'show' },
              :if => Proc.new { |p| p.repository && !p.repository.new_record? }
  menu.push :settings, { :controller => 'projects', :action => 'settings' }
end
