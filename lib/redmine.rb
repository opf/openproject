require 'redmine/access_control'
require 'redmine/menu_manager'
require 'redmine/mime_type'
require 'redmine/acts_as_watchable/init'
require 'redmine/acts_as_event/init'

begin
  require_library_or_gem 'rmagick' unless Object.const_defined?(:Magick)
rescue LoadError
  # RMagick is not available
end

REDMINE_SUPPORTED_SCM = %w( Subversion Darcs Mercurial Cvs )

# Permissions
Redmine::AccessControl.map do |map|
  # Project
  map.permission :view_project, {:projects => [:show, :activity, :changelog, :roadmap, :feeds]}, :public => true
  map.permission :search_project, {:search => :index}, :public => true
  map.permission :edit_project, {:projects => [:settings, :edit]}, :require => :member
  map.permission :manage_members, {:projects => [:settings, :add_member], :members => [:edit, :destroy]}, :require => :member
  map.permission :manage_versions, {:projects => [:settings, :add_version], :versions => [:edit, :destroy]}, :require => :member
  map.permission :manage_categories, {:projects => [:settings, :add_issue_category], :issue_categories => [:edit, :destroy]}, :require => :member
  
  # Issues
  map.permission :view_issues, {:projects => [:list_issues, :export_issues_csv, :export_issues_pdf], 
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
  map.permission :manage_pulic_queries, {:queries => [:new, :edit, :destroy]}, :require => :member
  map.permission :save_queries, {:queries => [:new, :edit, :destroy]}, :require => :loggedin
  # Gantt & calendar
  map.permission :view_gantt, :projects => :gantt
  map.permission :view_calendar, :projects => :calendar
  # Time tracking
  map.permission :log_time, {:timelog => :edit}, :require => :loggedin
  map.permission :view_time_entries, :timelog => [:details, :report]
  # News
  map.permission :view_news, {:projects => :list_news, :news => :show}, :public => true
  map.permission :manage_news, {:projects => :add_news, :news => [:edit, :destroy, :destroy_comment]}, :require => :member
  map.permission :comment_news, {:news => :add_comment}, :require => :loggedin
  # Documents
  map.permission :view_documents, :projects => :list_documents, :documents => [:show, :download]
  map.permission :manage_documents, {:projects => :add_document, :documents => [:edit, :destroy, :add_attachment, :destroy_attachment]}, :require => :loggedin
  # Wiki
  map.permission :view_wiki_pages, :wiki => [:index, :history, :diff, :special]
  map.permission :edit_wiki_pages, :wiki => [:edit, :preview, :add_attachment, :destroy_attachment]
  map.permission :delete_wiki_pages, {:wiki => :destroy}, :require => :member
  # Message boards
  map.permission :view_messages, {:boards => [:index, :show], :messages => [:show]}, :public => true
  map.permission :add_messages, {:messages => [:new, :reply]}, :require => :loggedin
  map.permission :manage_boards, {:boards => [:new, :edit, :destroy]}, :require => :member
  # Files
  map.permission :view_files, :projects => :list_files, :versions => :download
  map.permission :manage_files, {:projects => :add_file, :versions => :destroy_file}, :require => :loggedin
  # Repository
  map.permission :browse_repository, :repositories => [:show, :browse, :entry, :changes, :diff, :stats, :graph]
  map.permission :view_changesets, :repositories => [:show, :revisions, :revision]
end

# Project menu configuration
Redmine::MenuManager.map :project_menu do |menu|
  menu.push :label_overview, :controller => 'projects', :action => 'show'
  menu.push :label_calendar, :controller => 'projects', :action => 'calendar'
  menu.push :label_gantt, :controller => 'projects', :action => 'gantt'
  menu.push :label_issue_plural, :controller => 'projects', :action => 'list_issues'
  menu.push :label_report_plural, :controller => 'reports', :action => 'issue_report'
  menu.push :label_activity, :controller => 'projects', :action => 'activity'
  menu.push :label_news_plural, :controller => 'projects', :action => 'list_news'
  menu.push :label_change_log, :controller => 'projects', :action => 'changelog'
  menu.push :label_roadmap, :controller => 'projects', :action => 'roadmap'
  menu.push :label_document_plural, :controller => 'projects', :action => 'list_documents'
  menu.push :label_wiki, { :controller => 'wiki', :action => 'index', :page => nil }, :if => Proc.new { |p| p.wiki && !p.wiki.new_record? }
  menu.push :label_board_plural, { :controller => 'boards', :action => 'index', :id => nil }, :param => :project_id, :if => Proc.new { |p| p.boards.any? }
  menu.push :label_attachment_plural, :controller => 'projects', :action => 'list_files'
  menu.push :label_search, :controller => 'search', :action => 'index'
  menu.push :label_repository, { :controller => 'repositories', :action => 'show' }, :if => Proc.new { |p| p.repository && !p.repository.new_record? }
  menu.push :label_settings, :controller => 'projects', :action => 'settings'
end
