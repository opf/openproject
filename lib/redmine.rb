require 'redmine/access_control'
require 'redmine/menu_manager'
require 'redmine/mime_type'
require 'redmine/plugin'

begin
  require_library_or_gem 'RMagick' unless Object.const_defined?(:Magick)
rescue LoadError
  # RMagick is not available
end

REDMINE_SUPPORTED_SCM = %w( Subversion Darcs Mercurial Cvs )

# Permissions
Redmine::AccessControl.map do |map|
  map.permission :view_project, {:projects => [:show, :activity, :feeds]}, :public => true
  map.permission :search_project, {:search => :index}, :public => true
  map.permission :edit_project, {:projects => [:settings, :edit]}, :require => :member
  map.permission :select_project_modules, {:projects => :modules}, :require => :member
  map.permission :manage_members, {:projects => :settings, :members => [:new, :edit, :destroy]}, :require => :member
  map.permission :manage_versions, {:projects => [:settings, :add_version], :versions => [:edit, :destroy]}, :require => :member
  
  map.project_module :issue_tracking do |map|
    # Issue categories
    map.permission :manage_categories, {:projects => [:settings, :add_issue_category], :issue_categories => [:edit, :destroy]}, :require => :member
    # Issues
    map.permission :view_issues, {:projects => [:list_issues, :export_issues_csv, :export_issues_pdf, :changelog, :roadmap], 
                                  :issues => [:show, :export_pdf],
                                  :queries => :index,
                                  :reports => :issue_report}, :public => true                    
    map.permission :add_issues, {:projects => :add_issue}, :require => :loggedin
    map.permission :edit_issues, {:issues => [:edit, :destroy_attachment]}, :require => :loggedin
    map.permission :manage_issue_relations, {:issue_relations => [:new, :destroy]}, :require => :loggedin
    map.permission :add_issue_notes, {:issues => :add_note}, :require => :loggedin
    map.permission :change_issue_status, {:issues => :change_status}, :require => :loggedin
    map.permission :move_issues, {:projects => :move_issues}, :require => :loggedin
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
  end
  
  map.project_module :news do |map|
    map.permission :manage_news, {:projects => :add_news, :news => [:edit, :destroy, :destroy_comment]}, :require => :member
    map.permission :view_news, {:projects => :list_news, :news => :show}, :public => true
    map.permission :comment_news, {:news => :add_comment}, :require => :loggedin
  end

  map.project_module :documents do |map|
    map.permission :manage_documents, {:projects => :add_document, :documents => [:edit, :destroy, :add_attachment, :destroy_attachment]}, :require => :loggedin
    map.permission :view_documents, :projects => :list_documents, :documents => [:show, :download]
  end
  
  map.project_module :files do |map|
    map.permission :manage_files, {:projects => :add_file, :versions => :destroy_file}, :require => :loggedin
    map.permission :view_files, :projects => :list_files, :versions => :download
  end
    
  map.project_module :wiki do |map|
    map.permission :manage_wiki, {:wikis => [:edit, :destroy]}, :require => :member
    map.permission :rename_wiki_pages, {:wiki => :rename}, :require => :member
    map.permission :delete_wiki_pages, {:wiki => :destroy}, :require => :member
    map.permission :view_wiki_pages, :wiki => [:index, :history, :diff, :special]
    map.permission :edit_wiki_pages, :wiki => [:edit, :preview, :add_attachment, :destroy_attachment]
  end
    
  map.project_module :repository do |map|
    map.permission :manage_repository, :repositories => [:edit, :destroy]
    map.permission :browse_repository, :repositories => [:show, :browse, :entry, :changes, :diff, :stats, :graph]
    map.permission :view_changesets, :repositories => [:show, :revisions, :revision]
  end

  map.project_module :boards do |map|
    map.permission :manage_boards, {:boards => [:new, :edit, :destroy]}, :require => :member
    map.permission :view_messages, {:boards => [:index, :show], :messages => [:show]}, :public => true
    map.permission :add_messages, {:messages => [:new, :reply]}, :require => :loggedin
  end
end

# Project menu configuration
Redmine::MenuManager.map :project_menu do |menu|
  menu.push :label_overview, :controller => 'projects', :action => 'show'
  menu.push :label_activity, :controller => 'projects', :action => 'activity'
  menu.push :label_roadmap, :controller => 'projects', :action => 'roadmap'
  menu.push :label_issue_plural, :controller => 'projects', :action => 'list_issues'
  menu.push :label_news_plural, :controller => 'projects', :action => 'list_news'
  menu.push :label_document_plural, :controller => 'projects', :action => 'list_documents'
  menu.push :label_wiki, { :controller => 'wiki', :action => 'index', :page => nil }, :if => Proc.new { |p| p.wiki && !p.wiki.new_record? }
  menu.push :label_board_plural, { :controller => 'boards', :action => 'index', :id => nil }, :param => :project_id, :if => Proc.new { |p| p.boards.any? }
  menu.push :label_attachment_plural, :controller => 'projects', :action => 'list_files'
  menu.push :label_repository, { :controller => 'repositories', :action => 'show' }, :if => Proc.new { |p| p.repository && !p.repository.new_record? }
  menu.push :label_settings, :controller => 'projects', :action => 'settings'
end
