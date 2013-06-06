module Menus::Project
  module Modules

    Redmine::MenuManager.map :'project/modules' do |menu|
      menu.push :overview,
                { :controller => '/projects',
                  :action => 'show',
                  :id => :project }

      menu.push :activity,
                { :controller => '/activities',
                  :action => 'index',
                  :id => :project }

      menu.push :roadmap,
                { :controller => '/versions',
                  :action => 'index',
                  :id => :project },
                :if => Proc.new { |p| p.shared_versions.any? }

      menu.push :issues,
                { :controller => '/issues',
                  :action => 'index',
                  :id => :project },
                :caption => :label_issue_plural

      menu.push :new_issue,
                { :controller => '/work_packages',
                  :action => 'new',
                  :type => 'Issue' },
                :param => :project_id,
                :caption => :label_issue_new,
                :parent => :issues,
                :html => { :accesskey => Redmine::AccessKeys.key_for(:new_issue) }

      menu.push :view_all_issues,
                { :controller => '/issues',
                  :action => 'all' },
                :param => :project_id,
                :caption => :label_issue_view_all,
                :parent => :issues

      menu.push :summary_field,
                { :controller => '/issues/reports',
                  :action => 'report' },
                :param => :project_id,
                :caption => :label_workflow_summary,
                :parent => :issues

      menu.push :calendar,
                { :controller => '/calendars',
                  :action => 'show' },
                :param => :project_id,
                :caption => :label_calendar

      menu.push :news,
                { :controller => '/news',
                  :action => 'index' },
                :param => :project_id,
                :caption => :label_news_plural

      menu.push :new_news,
                { :controller => '/news',
                  :action => 'new' },
                :param => :project_id,
                :caption => :label_news_new,
                :parent => :news,
                :if => Proc.new { |p| User.current.allowed_to?(:manage_news, p.project) }

      menu.push :documents,
                { :controller => '/documents',
                  :action => 'index' },
                :param => :project_id,
                :caption => :label_document_plural

      menu.push :boards,
                { :controller => '/boards',
                  :action => 'index',
                  :id => nil },
                :param => :project_id,
                :if => Proc.new { |p| p.boards.any? },
                :caption => :label_board_plural

      menu.push :files,
                { :controller => '/files',
                  :action => 'index' },
                :param => :project_id,
                :caption => :label_file_plural

      menu.push :repository,
                { :controller => '/repositories', :action => 'show' },
                :if => Proc.new { |p| p.repository && !p.repository.new_record? }

      # Project menu entries
      # * Timelines
      # ** Reports
      # ** Associations a.k.a. Dependencies
      # ** Reportings
      # ** Planning Elemnts
      # ** Papierkorb

      {:param => :project_id}.tap do |options|

        menu.push :timelines_timelines,
                  {:controller => '/timelines/timelines_timelines', :action => 'index'},
                  options.merge(:caption => :'timelines.project_menu.timelines')

        options.merge(:parent => :timelines_timelines).tap do |rep_options|

          menu.push :timelines_reports,
                    {:controller => '/timelines/timelines_timelines', :action => 'index'},
                    rep_options.merge(:caption => :'timelines.project_menu.reports')

          menu.push :timelines_project_associations,
                    {:controller => '/timelines/timelines_project_associations', :action => 'index'},
                    rep_options.merge(:caption => :'timelines.project_menu.project_associations',
                                      :if => Proc.new { |p| p.timelines_project_type.try :allows_association })

          menu.push :timelines_reportings,
                    {:controller => '/timelines/timelines_reportings', :action => 'index'},
                    rep_options.merge(:caption => :'timelines.project_menu.reportings')

          menu.push :timelines_planning_elements,
                    {:controller => '/timelines/timelines_planning_elements', :action => 'all'},
                    rep_options.merge(:caption => :'timelines.project_menu.planning_elements')

          menu.push :timelines_recycle_bin,
                    {:controller => '/timelines/timelines_planning_elements', :action => 'recycle_bin'},
                    rep_options.merge(:caption => :'timelines.project_menu.recycle_bin')

        end
      end

      menu.push :settings,
                { :controller => '/projects', :action => 'settings' },
                :caption => :label_project_settings,
                :last => true
    end
  end
end

