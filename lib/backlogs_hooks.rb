module BacklogsPlugin
  module Hooks
    class LayoutHook < Redmine::Hook::ViewListener
      # this ought to be view_issues_sidebar_queries_bottom, but
      # the entire queries toolbar is disabled if you don't have
      # custom queries

      include RbCommonHelper
      def view_issues_sidebar_planning_bottom(context={ })
        locals = {}
        locals[:sprints] = context[:project] ? Sprint.open_sprints(context[:project]) : []
        locals[:project] = context[:project]
        locals[:sprint] = nil
        locals[:webcal] = (context[:request].ssl? ? 'webcals' : 'webcal')

        return '' unless locals[:project]
        return '' if locals[:project].blank?
        return '' unless locals[:project].module_enabled?('backlogs')

        user = User.find_by_id(context[:request].session[:user_id])
        locals[:key] = user ? user.api_key : nil

        q = context[:request].session[:query]
        if q && q[:filters]
          sprint = q[:filters]['fixed_version_id']
          if sprint && sprint[:operator] == '=' && sprint[:values].size == 1
            locals[:sprint] = Sprint.find_by_id(sprint[:values][0])
          end
        end

        context[:controller].send(:render_to_string, {
            :partial => 'shared/view_issues_sidebar',
            :locals => locals
        })
      end

      def view_issues_show_details_bottom(context = {})
        issue = context[:issue]

        return '' unless issue.project.module_enabled? 'backlogs'

        snippet = ''

        if issue.is_story?
          snippet += %Q{
            <tr>
              <th class="story-points">#{l(:field_story_points)}:</th>
              <td class="story-points">#{Story.find(issue.id).points_display}</td>
            </tr>
          }

          if Setting.plugin_redmine_backlogs[:show_statistics]
            vbe = issue.velocity_based_estimate
            snippet += %Q{
              <tr>
                <th class="velocity-based-estimate">#{l(:field_velocity_based_estimate)}:</th>
                <td class="velocity-based-estimate">#{vbe ? vbe.to_s + ' days' : '-'}</td>
              </tr>
            }
          end
        end

        snippet += %Q{
          <tr>
            <th class="remaining_hours">#{l(:field_remaining_hours)}:</th>
            <td class="remaining_hours">#{l_hours(issue.remaining_hours)}</td>
          </tr>
        }

        snippet
      end

      def view_issues_form_details_bottom(context = {})
        snippet = ''
        issue = context[:issue]

        return '' unless issue.project.module_enabled? 'backlogs'

        snippet << %(<div id="backlogs-attributes" class="attributes">)
        snippet << %(<div class="splitcontentleft">)

        if issue.is_story?
          snippet << '<p>'
          snippet << context[:form].text_field(:story_points, :size => 3)
          snippet << '</p>'

          if issue.descendants.length != 0
            snippet << javascript_include_tag_backlogs('lib/jquery.js')
            snippet << javascript_tag(<<-JS)
              var $j = jQuery.noConflict();

              $j(document).ready(function() {
                $j('#issue_estimated_hours').attr('disabled', 'disabled');
                $j('#issue_remaining_hours').attr('disabled', 'disabled');
                $j('#issue_done_ratio').attr('disabled', 'disabled');
                $j('#issue_start_date').parent().hide();
                $j('#issue_due_date').parent().hide();
              });
            JS
          end
        end

        snippet << '<p>'
        snippet << context[:form].text_field(:remaining_hours, :size => 3)
        snippet << ' '
        snippet << l(:field_hours)
        snippet << '</p>'

        params = context[:controller].params
        if issue.is_story? && params[:copy_from]
          snippet << "<p><label for='link_to_original'>#{l(:rb_label_link_to_original)}</label>"
          snippet << "#{check_box_tag('link_to_original', params[:copy_from], true)}</p>"

          snippet << "<p><label>#{l(:rb_label_copy_tasks)}</label>"
          snippet << "#{radio_button_tag('copy_tasks', 'open:' + params[:copy_from], true)} #{l(:rb_label_copy_tasks_open)}<br />"
          snippet << "#{radio_button_tag('copy_tasks', 'none', false)} #{l(:rb_label_copy_tasks_none)}<br />"
          snippet << "#{radio_button_tag('copy_tasks', 'all:' + params[:copy_from], false)} #{l(:rb_label_copy_tasks_all)}</p>"
        end

        snippet << %(</div>) * 2

        snippet
      end

      def view_versions_show_bottom(context={ })
        version = context[:version]
        project = version.project

        return '' unless project.module_enabled? 'backlogs'

        snippet = ''

        if User.current.allowed_to?(:edit_wiki_pages, project)
          snippet += '<span id="edit_wiki_page_action">'
          snippet += link_to l(:button_edit_wiki), {:controller => 'rb_wikis', :action => 'edit', :project_id => project.id, :sprint_id => version.id }, :class => 'icon icon-edit'
          snippet += '</span>'

          # this wouldn't be necesary if the schedules plugin
          # didn't disable the contextual hook
          snippet += javascript_include_tag_backlogs('lib/jquery.js')
          snippet += javascript_tag(<<-JS)
            var $j = jQuery.noConflict();
            $j(document).ready(function() {
              $j('#edit_wiki_page_action').detach().appendTo("div.contextual");
            });
          JS
        end
      end

      def view_my_account(context={ })
        return context[:controller].send(:render_to_string, {
            :partial => 'shared/view_my_account',
            :locals => {:user => context[:user], :color => context[:user].backlogs_preference(:task_color) }
          })
      end

      def controller_issues_new_after_save(context={ })
        params = context[:params]
        issue = context[:issue]

        return unless issue.project.module_enabled? 'backlogs'

        if issue.is_story?
          if params[:link_to_original]
            rel = IssueRelation.new

            rel.issue_from_id = Integer(params[:link_to_original])
            rel.issue_to_id = issue.id
            rel.relation_type = IssueRelation::TYPE_RELATES
            rel.save
          end

          if params[:copy_tasks]
            params[:copy_tasks] += ':' if params[:copy_tasks] !~ /:/
            action, id = *(params[:copy_tasks].split(/:/))

            story = (id == '' ? nil : Story.find(Integer(id)))

            if ! story.nil? && action != 'none'
              tasks = story.tasks
              case action
                when 'open'
                  tasks = tasks.select{|t| !t.closed?}
                when 'all', 'none'
                  #
                else
                  raise "Unexpected value #{params[:copy_tasks]}"
              end

              tasks.each {|t|
                nt = Task.new
                nt.copy_from(t)
                nt.parent_issue_id = issue.id
                nt.save
              }
            end
          end
        end
      end
    end
  end
end
