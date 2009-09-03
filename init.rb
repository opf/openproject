require 'redmine'

# Patches to the Redmine core
require 'issue_patch'
require 'version_patch'
require 'dispatcher'
require 'weekdays'

Dispatcher.to_prepare do
  Issue.send(:include, Backlogs::IssuePatch)
  Version.send(:include, Backlogs::VersionPatch)
end

Redmine::Plugin.register :redmine_backlogs do
  name 'Redmine Backlogs plugin'
  author 'Mark Maglana'
  description 'Agile/Scrum backlog management tool'
  version '0.0.1'
  
  
  project_module :backlogs do
    permission :backlogs, { :backlogs => [:index, :show, :update],
                            :charts   => [:show],
                            :comments => [:index, :create],
                            :items    => [:index, :create, :update],
                            :tasks    => [:index]                   
                          }, :public => false
  end

  menu :project_menu, 
       :backlogs, 
       { :controller => 'backlogs', :action => :index }, 
       :caption => 'Backlogs', 
       :after   => :roadmap, 
       :param   => :project_id
end
