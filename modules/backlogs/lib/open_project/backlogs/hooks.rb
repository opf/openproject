#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Backlogs::Hooks
  class Hook < Redmine::Hook::Listener
    include ActionView::Helpers::TagHelper
    include ActionView::Context
    include WorkPackagesHelper

    def work_packages_show_attributes(context = {})
      work_package = context[:work_package]
      attributes = context[:attributes]

      return unless work_package.backlogs_enabled?
      return if context[:from] == 'OpenProject::Backlogs::WorkPackageView::FieldsParagraph'

      attributes << work_package_show_story_points_attribute(work_package)
      attributes << work_package_show_remaining_hours_attribute(work_package)

      attributes
    end

    private

    def work_package_show_story_points_attribute(work_package)
      return nil unless work_package.is_story?

      work_package_show_table_row(:story_points, :"story-points") do
        work_package.story_points ? work_package.story_points.to_s : empty_element_tag
      end
    end

    def work_package_show_remaining_hours_attribute(work_package)
      work_package_show_table_row(:remaining_hours) do
        work_package.remaining_hours ? l_hours(work_package.remaining_hours) : empty_element_tag
      end
    end
  end

  class LayoutHook < Redmine::Hook::ViewListener
    include RbCommonHelper

    # TODO: there are hook implementations in here that need to be ported
    #       to render a partial instead of returning a hand crafted snippet

    render_on :view_work_packages_form_details_bottom,
              partial: 'hooks/backlogs/view_work_packages_form_details_bottom'

    def view_versions_show_bottom(context = {})
      version = context[:version]
      project = version.project

      return '' unless project.module_enabled? 'backlogs'

      snippet = ''

      if User.current.allowed_to?(:edit_wiki_pages, project)
        snippet += '<span id="edit_wiki_page_action">'
        snippet += link_to l(:button_edit_wiki), { controller: '/rb_wikis', action: 'edit', project_id: project.id, sprint_id: version.id }, class: 'icon icon-edit'
        snippet += '</span>'

        # This wouldn't be necesary if the schedules plugin didn't disable the
        # contextual hook
        snippet += context[:hook_caller].nonced_javascript_tag(<<-JS)
          (function ($) {
            $(document).ready(function() {
              $('#edit_wiki_page_action').detach().appendTo("div.contextual");
            });
          }(jQuery))
        JS
      end
    end

    def view_my_settings(context = {})
      context[:controller].send(
        :render_to_string,
        partial: 'shared/view_my_settings',
        locals: {
          user: context[:user],
          color: context[:user].backlogs_preference(:task_color),
          versions_default_fold_state:
            context[:user].backlogs_preference(:versions_default_fold_state) })
    end

    def controller_work_package_new_after_save(context = {})
      params = context[:params]
      work_package = context[:work_package]

      return unless work_package.backlogs_enabled?

      if work_package.is_story?
        if params[:link_to_original]
          rel = Relation.new

          rel.from_id = Integer(params[:link_to_original])
          rel.to_id = work_package.id
          rel.relation_type = Relation::TYPE_RELATES
          rel.save
        end

        if params[:copy_tasks]
          params[:copy_tasks] += ':' if params[:copy_tasks] !~ /:/
          action, id = *(params[:copy_tasks].split(/:/))

          story = (id.nil? ? nil : Story.find(Integer(id)))

          if !story.nil? && action != 'none'
            tasks = story.tasks
            case action
            when 'open'
              tasks = tasks.select { |t| !t.closed? }
            when 'all', 'none'
            #
            else
              raise "Unexpected value #{params[:copy_tasks]}"
            end

            tasks.each {|t|
              nt = Task.new
              nt.copy_from(t)
              nt.parent_id = work_package.id
              nt.save
            }
          end
        end
      end
    end
  end
end
