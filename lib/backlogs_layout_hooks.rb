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

            def view_issues_show_details_bottom(context={ })
                issue = context[:issue]
                snippet = ''

                if issue.is_story?
                    snippet += "<tr><th>Story points</th><td>#{Story.find(issue.id).points_display}</td></tr>"
                end

                if issue.is_task? || (issue.is_story? && issue.descendants.length == 0)
                    snippet += "<tr><th>Remaining hours</th><td>#{issue.remaining_hours}</td></tr>"
                end

                return snippet
            end

            def view_issues_form_details_bottom(context={ })
                snippet = ''
                issue = context[:issue]
                #project = context[:project]

                #developers = project.members.select {|m| m.user.allowed_to?(:log_time, project)}.collect{|m| m.user}
                #developers = select_tag("time_entry[user_id]", options_from_collection_for_select(developers, :id, :name, User.current.id))
                #developers = developers.gsub(/\n/, '')

                if issue.is_story?
                    snippet += '<p>'
                    snippet += context[:form].label(:story_points)
                    snippet += context[:form].text_field(:story_points, :size => 3)
                    snippet += '</p>'

                    if issue.descendants.length != 0
                        snippet += javascript_include_tag 'jquery-1.4.2.min.js', :plugin => 'redmine_backlogs'
                        snippet += <<-generatedscript

                            <script type="text/javascript">
                                var $j = jQuery.noConflict();

                                $j(document).ready(function() {
                                    $j('#issue_estimated_hours').attr('disabled', 'disabled');
                                    $j('#issue_done_ratio').attr('disabled', 'disabled');
                                    $j('#issue_start_date').parent().hide();
                                    $j('#issue_due_date').parent().hide();
                                });
                            </script>
                        generatedscript
                    end
                end

                if issue.is_task? || (issue.is_story? && issue.descendants.length == 0)
                    snippet += '<p>'
                    snippet += context[:form].label(:remaining_hours)
                    snippet += context[:form].text_field(:remaining_hours, :size => 3)
                    snippet += '</p>'
                end

                return snippet
            end

            def view_versions_show_bottom(context={ })
                version = context[:version]
                project = version.project

                snippet = ''

                if User.current.allowed_to?(:edit_wiki_pages, project)
                    snippet += '<span id="edit_wiki_page_action">'
                    snippet += link_to l(:button_edit_wiki), {:controller => 'backlogs', :action => 'wiki_page_edit', :project_id => project.id, :sprint_id => version.id }, :class => 'icon icon-edit'
                    snippet += '</span>'

                    # this wouldn't be necesary if the schedules plugin
                    # didn't disable the contextual hook
                    snippet += javascript_include_tag 'jquery-1.4.2.min.js', :plugin => 'redmine_backlogs'
                    snippet += <<-generatedscript

                        <script type="text/javascript">
                                var $j = jQuery.noConflict();
                            $j(document).ready(function() {
                                $j('#edit_wiki_page_action').detach().appendTo("div.contextual");
                            });
                        </script>
                    generatedscript
                end
            end

        end
    end
end
