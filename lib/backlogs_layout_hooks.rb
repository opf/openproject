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
                                        :sprint_id => sprint.id
                                    })
                    links += content_tag(:br)
                }

                return content_tag(:div, content_tag(:h3, l(:backlogs_sprints)) + links)
            end

            def view_issues_form_details_bottom(context={ })
                snippet = ''
                issue = context[:issue]
                #project = context[:project]

                #developers = project.members.select {|m| m.user.allowed_to?(:log_time, project)}.collect{|m| m.user}
                #developers = select_tag("time_entry[user_id]", options_from_collection_for_select(developers, :id, :name, User.current.id))
                #developers = developers.gsub(/\n/, '')

                if issue.tracker_id == Integer(Setting.plugin_redmine_backlogs[:story_tracker])
                    snippet += '<p>'
                    snippet += context[:form].label(:story_points)
                    snippet += context[:form].text_field(:story_points, :size => 3)
                    snippet += '</p>'

                    snippet += javascript_include_tag 'jquery-1.4.2.min.js', :plugin => 'redmine_backlogs'

                    if issue.descendants.length != 0
                        snippet += <<-generatedscript

                            <script type="text/javascript">
                                $(document).ready(function() {
                                    $('#issue_estimated_hours').attr('disabled', 'disabled');
                                    $('#issue_done_ratio').attr('disabled', 'disabled');
                                    $('#issue_start_date').parent().hide();
                                    $('#issue_due_date').parent().hide();
                                });
                            </script>
                        generatedscript
                    end

                elsif issue.tracker_id == Integer(Setting.plugin_redmine_backlogs[:story_tracker])
                    snippet += context[:form].label(:remaining_hours)
                    snippet += context[:form].text_field(:remaining_hours, :size => 3)
                end

                return snippet
            end

        end
    end
end
