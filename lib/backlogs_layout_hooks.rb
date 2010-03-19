module BacklogsPlugin
    module Hooks
        class LayoutHook < Redmine::Hook::ViewListener
            def view_issues_sidebar_queries_bottom(context={ })
                links = ''
                project = context[:project]
                project_id = project.id

                Sprint.open_sprints(project).each { |sprint|
                    links += link_to(sprint.name, {
                                        :controller => 'backlogs',
                                        :action => 'select_sprint',
                                        :project_id => project_id,
                                        :sprint_id => 1 # sprint.id
                                    })
                    links += content_tag(:br)
                }

                return content_tag(:div, content_tag(:h3, l(:backlogs_sprints)) + links)
            end
        end
    end
end
