#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Project::Copy
  def self.included(base)
    base.send :include, CopyModel
    base.send :include, self::CopyMethods

    # things that are explicitly excluded when copying a project
    base.not_to_copy ['id', 'name', 'identifier', 'status', 'lft', 'rgt']

    # specify the order of associations to copy
    base.copy_precedence ['members', 'versions', 'categories', 'work_packages', 'wiki']
  end

  module CopyMethods
    def copy_attributes(project)
      super
      with_model(project) do |project|
        self.enabled_modules = project.enabled_modules
        self.types = project.types
        self.custom_values = project.custom_values.map(&:clone)
        self.work_package_custom_fields = project.work_package_custom_fields
      end
      return self
    rescue ActiveRecord::RecordNotFound
      return nil
    end

    def copy_associations(from_model, options = {})
      super(from_model, options) if save
    end

    private

    # Copies wiki from +project+
    def copy_wiki(project)
      # Check that the source project has a wiki first
      unless project.wiki.nil?
        self.wiki = build_wiki(project.wiki.attributes.dup.except('id', 'project_id'))
        copy_wiki_pages(project)
        copy_wiki_menu_items(project)
      end
    end

    # Copies wiki pages from +project+, requires a wiki to be already set
    def copy_wiki_pages(project)
      wiki_pages_map = {}
      project.wiki.pages.each do |page|
        # Skip pages without content
        next if page.content.nil?
        new_wiki_content = WikiContent.new(page.content.attributes.dup.except('id', 'page_id', 'updated_at'))
        new_wiki_page = WikiPage.new(page.attributes.dup.except('id', 'wiki_id', 'created_on', 'parent_id'))
        new_wiki_page.content = new_wiki_content

        wiki.pages << new_wiki_page
        wiki_pages_map[page.id] = new_wiki_page
      end
      wiki.save
      # Reproduce page hierarchy
      project.wiki.pages.each do |page|
        if page.parent_id && wiki_pages_map[page.id]
          wiki_pages_map[page.id].parent = wiki_pages_map[page.parent_id]
          wiki_pages_map[page.id].save
        end
      end
    end

    # Copies wiki_menu_items from +project+, requires a wiki to be already set
    def copy_wiki_menu_items(project)
      wiki_menu_items_map = {}
      project.wiki.wiki_menu_items.each do |item|
        new_item = MenuItems::WikiMenuItem.new
        new_item.force_attributes = item.attributes.dup.except('id', 'wiki_id', 'parent_id')
        new_item.wiki = wiki
        (wiki_menu_items_map[item.id] = new_item.reload) if new_item.save
      end
      project.wiki.wiki_menu_items.each do |item|
        if item.parent_id && (copy = wiki_menu_items_map[item.id])
          copy.parent = wiki_menu_items_map[item.parent_id]
          copy.save
        end
      end
    end

    # Copies versions from +project+
    def copy_versions(project)
      project.versions.each do |version|
        new_version = Version.new
        new_version.attributes = version.attributes.dup.except('id', 'project_id', 'created_on', 'updated_at')
        versions << new_version
      end
    end

    # Copies issue categories from +project+
    def copy_categories(project)
      project.categories.each do |category|
        new_category = Category.new
        new_category.send(:assign_attributes, category.attributes.dup.except('id', 'project_id'), without_protection: true)
        categories << new_category
      end
    end

    # Copies issues from +project+
    def copy_work_packages(project)
      # Stores the source issue id as a key and the copied issues as the
      # value.  Used to map the two together for issue relations.
      work_packages_map = {}

      # Get issues sorted by root_id, lft so that parent issues
      # get copied before their children
      project.work_packages.reorder('root_id, lft').each do |issue|
        new_issue = WorkPackage.new
        new_issue.copy_from(issue)
        new_issue.project = self
        # Reassign fixed_versions by name, since names are unique per
        # project and the versions for self are not yet saved
        if issue.fixed_version
          new_version = versions.select { |v| v.name == issue.fixed_version.name }.first
          if new_version
            new_issue.instance_variable_set(:@changed_attributes, new_issue.changed_attributes.merge('fixed_version_id' => new_version.id))
            new_issue.fixed_version = new_version
          end
        end
        # Reassign the category by name, since names are unique per
        # project and the categories for self are not yet saved
        if issue.category
          new_issue.category = categories.select { |c| c.name == issue.category.name }.first
        end
        # Parent issue
        if issue.parent_id
          if (copied_parent = work_packages_map[issue.parent_id]) && copied_parent.reload
            new_issue.parent_id = copied_parent.id
          end
        end
        work_packages << new_issue

        if new_issue.new_record?
          logger.info "Project#copy_work_packages: work unit ##{issue.id} could not be copied: #{new_issue.errors.full_messages}" if logger && logger.info
        else
          work_packages_map[issue.id] = new_issue unless new_issue.new_record?
        end
      end

      # reload all work_packages in our map, they might be modified by movement in their tree
      work_packages_map.each { |_, v| v.reload }

      # Relations after in case issues related each other
      project.work_packages.each do |issue|
        new_issue = work_packages_map[issue.id]
        unless new_issue
          # Issue was not copied
          next
        end

        # Relations
        issue.relations_from.each do |source_relation|
          new_relation = Relation.new
          new_relation.force_attributes = source_relation.attributes.dup.except('id', 'from_id', 'to_id')
          new_relation.to = work_packages_map[source_relation.to_id]
          if new_relation.to.nil? && Setting.cross_project_work_package_relations?
            new_relation.to = source_relation.to
          end
          new_relation.from = new_issue
          new_relation.save
        end

        issue.relations_to.each do |source_relation|
          new_relation = Relation.new
          new_relation.force_attributes = source_relation.attributes.dup.except('id', 'from_id', 'to_id')
          new_relation.from = work_packages_map[source_relation.from_id]
          if new_relation.from.nil? && Setting.cross_project_work_package_relations?
            new_relation.from = source_relation.from
          end
          new_relation.to = new_issue
          new_relation.save
        end
      end
    end

    # Copies members from +project+
    def copy_members(project)
      # Copy users first, then groups to handle members with inherited and given roles
      members_to_copy = []
      members_to_copy += project.memberships.select { |m| m.principal.is_a?(User) }
      members_to_copy += project.memberships.select { |m| !m.principal.is_a?(User) }
      members_to_copy.each do |member|
        new_member = Member.new
        new_member.send(:assign_attributes, member.attributes.dup.except('id', 'project_id', 'created_on'), without_protection: true)
        # only copy non inherited roles
        # inherited roles will be added when copying the group membership
        role_ids = member.member_roles.reject(&:inherited?).map(&:role_id)
        next if role_ids.empty?
        new_member.role_ids = role_ids
        new_member.project = self
        memberships << new_member
      end

      # Update the omitted attributes for the copied memberships
      memberships.each do |new_member|
        member = project.memberships.find_by_user_id(new_member.user_id)
        Redmine::Hook.call_hook(:copy_project_add_member, new_member: new_member, member: member)
        new_member.save
      end
    end

    # Copies queries from +project+
    def copy_queries(project)
      project.queries.each do |query|
        new_query = ::Query.new name: '_'
        new_query.attributes = query.attributes.dup.except('id', 'project_id', 'sort_criteria')
        new_query.sort_criteria = query.sort_criteria if query.sort_criteria
        new_query.project = self
        queries << new_query
      end
    end

    # Copies boards from +project+
    def copy_boards(project)
      project.boards.each do |board|
        new_board = Board.new
        new_board.attributes = board.attributes.dup.except('id', 'project_id', 'topics_count', 'messages_count', 'last_message_id')
        topics = board.topics.where('parent_id is NULL')
        topics.each do |topic|
          new_topic = Message.new
          new_topic.attributes = topic.attributes.dup.except('id', 'board_id', 'author_id', 'replies_count', 'last_reply_id', 'created_on', 'updated_on')
          new_topic.board = new_board
          new_topic.author_id = topic.author_id
          new_board.topics << new_topic
        end

        new_board.project = self
        boards << new_board
      end
    end

    # Copies project associations from +project+
    def copy_project_associations(project)
      [:project_a, :project_b].each do |association_type|
        project.send(:"#{association_type}_associations").each do |association|
          new_association = ProjectAssociation.new
          new_association.force_attributes = association.attributes.dup.except('id', "#{association_type}_id")
          new_association.send(:"#{association_type}=", self)
          new_association.save
        end
      end
    end

    # copies timeline associations from +project+
    def copy_timelines(project)
      project.timelines.each do |timeline|
        copied_timeline = Timeline.new
        copied_timeline.force_attributes = timeline.attributes.dup.except('id', 'project_id', 'options')
        copied_timeline.options = timeline.options if timeline.options.present?
        copied_timeline.project = self
        copied_timeline.save
      end
    end

    # copies reporting associations from +project+
    def copy_reportings(project)
      project.reportings_via_source.each do |reporting|
        copied_reporting = Reporting.new
        copied_reporting.force_attributes = reporting.attributes.dup.except('id', 'project_id')
        copied_reporting.project = self
        copied_reporting.save
      end
      project.reportings_via_target.each do |reporting|
        copied_reporting = Reporting.new
        copied_reporting.force_attributes = reporting.attributes.dup.except('id', 'reporting_to_project')
        copied_reporting.reporting_to_project = self
        copied_reporting.save
      end
    end
  end
end
