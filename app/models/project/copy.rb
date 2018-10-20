#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module Project::Copy
  def self.included(base)
    base.send :include, CopyModel
    base.send :include, self::CopyMethods

    # things that are explicitly excluded when copying a project
    base.not_to_copy ['id', 'created_on', 'updated_on', 'name', 'identifier', 'status', 'lft', 'rgt']

    # specify the order of associations to copy
    base.copy_precedence ['members', 'versions', 'categories', 'work_packages', 'wiki', 'custom_values']
  end

  module CopyMethods
    def copy_attributes(project)
      super
      with_model(project) do |project|
        self.enabled_module_names = project.enabled_module_names
        self.types = project.types
        self.work_package_custom_fields = project.work_package_custom_fields
        self.custom_field_values = project.custom_value_attributes
      end

      self
    rescue ActiveRecord::RecordNotFound
      nil
    end

    def copy_associations(from_model, options = {})
      super(from_model, options) if save
    end

    private

    # Copies custom values from +project+
    def copy_custom_values(project, selected_copies = [])
      self.custom_values = project.custom_values.map(&:dup)
    end

    # Copies wiki from +project+
    def copy_wiki(project, selected_copies = [])
      # Check that the source project has a wiki first
      unless project.wiki.nil?
        self.wiki = build_wiki(project.wiki.attributes.dup.except('id', 'project_id'))
        self.wiki.wiki_menu_items.delete_all
        copy_wiki_pages(project)
        copy_wiki_menu_items(project)
      end
    end

    # Copies wiki pages from +project+, requires a wiki to be already set
    def copy_wiki_pages(project, selected_copies = [])
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

      # Copy attachments
      if selected_copies.include? :wiki_page_attachments
        wiki_pages_map.each do |old_page, new_page|
          copy_attachments(old_page, new_page)
        end
      end
    end

    # Copies wiki_menu_items from +project+, requires a wiki to be already set
    def copy_wiki_menu_items(project, selected_copies = [])
      wiki_menu_items_map = {}
      project.wiki.wiki_menu_items.each do |item|
        new_item = MenuItems::WikiMenuItem.new
        new_item.attributes = item.attributes.dup.except('id', 'wiki_id', 'parent_id')
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
    def copy_versions(project, selected_copies = [])
      project.versions.each do |version|
        new_version = Version.new
        new_version.attributes = version.attributes.dup.except('id', 'project_id', 'created_on', 'updated_at')
        versions << new_version
      end
    end

    # Copies issue categories from +project+
    def copy_categories(project, selected_copies = [])
      project.categories.each do |category|
        new_category = Category.new
        new_category.send(:assign_attributes, category.attributes.dup.except('id', 'project_id'))
        categories << new_category
      end
    end

    # Copies issues from +project+
    def copy_work_packages(project, selected_copies = [])
      # Stores the source issue id as a key and the copied issues as the
      # value.  Used to map the two together for issue relations.
      work_packages_map = {}

      # Get issues sorted by their depth in the hierarchy tree
      # so that parents get copied before their children.
      to_copy = project
                .work_packages
                .order_by_ancestors('asc')

      to_copy.each do |issue|
        parent_id = (work_packages_map[issue.parent_id] && work_packages_map[issue.parent_id].id) || issue.parent_id

        overrides = { project: self,
                      parent_id: parent_id,
                      fixed_version: issue.fixed_version && versions.detect { |v| v.name == issue.fixed_version.name } }

        service_call = WorkPackages::CopyService
                       .new(user: User.current,
                            work_package: issue,
                            contract_class: WorkPackages::CopyProjectContract)
                       .call(attributes: overrides)

        if service_call.success?
          new_work_package = service_call.result

          work_packages_map[issue.id] = new_work_package
        elsif logger && logger.info
          compiled_errors << service_call.errors
          logger.info <<-MSG
            Project#copy_work_packages: work package ##{issue.id} could not be copied: #{service_call.errors.full_messages}
          MSG
        end
      end

      # reload all work_packages in our map, they might be modified by movement in their tree
      work_packages_map.each_value(&:reload)

      # Relations and attachments after in case issues related each other
      to_copy.each do |issue|
        new_issue = work_packages_map[issue.id]
        unless new_issue
          # Issue was not copied
          next
        end

        # Attachments
        if selected_copies.include? :work_package_attachments
          copy_attachments(issue, new_issue)
        end

        # Relations
        issue.relations_to.non_hierarchy.direct.each do |source_relation|
          new_relation = Relation.new
          new_relation.attributes = source_relation.attributes.dup.except('id', 'from_id', 'to_id', 'relation_type')
          new_relation.to = work_packages_map[source_relation.to_id]
          if new_relation.to.nil? && Setting.cross_project_work_package_relations?
            new_relation.to = source_relation.to
          end
          new_relation.from = new_issue
          new_relation.save
        end

        issue.relations_from.non_hierarchy.direct.each do |source_relation|
          new_relation = Relation.new
          new_relation.attributes = source_relation.attributes.dup.except('id', 'from_id', 'to_id', 'relation_type')
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
    def copy_members(project, selected_copies = [])
      # Copy users first, then groups to handle members with inherited and given roles
      members_to_copy = []
      members_to_copy += project.memberships.select { |m| m.principal.is_a?(User) }
      members_to_copy += project.memberships.reject { |m| m.principal.is_a?(User) }
      members_to_copy.each do |member|
        new_member = Member.new
        new_member.send(:assign_attributes, member.attributes.dup.except('id', 'project_id', 'created_on'))
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
        member = project.memberships.find_by(user_id: new_member.user_id)
        Redmine::Hook.call_hook(:copy_project_add_member, new_member: new_member, member: member)
        new_member.save
      end
    end

    # Copies queries from +project+
    def copy_queries(project, selected_copies = [])
      project.queries.includes(:query_menu_item).each do |query|
        new_query = ::Query.new name: '_'
        new_query.attributes = query.attributes.dup.except('id', 'project_id', 'sort_criteria')
        new_query.sort_criteria = query.sort_criteria if query.sort_criteria
        new_query.set_context
        new_query.project = self
        queries << new_query

        # Copy menu item if any
        if query.query_menu_item && new_query.persisted?
          ::MenuItems::QueryMenuItem.create(
            navigatable_id: new_query.id,
            name: SecureRandom.uuid,
            title: query.query_menu_item.title
          )
        end
      end

      # Update the context in the new project, otherwise, the filters will be invalid
      queries.map { |q| q.set_context }
    end

    # Copies boards from +project+
    def copy_boards(project, selected_copies = [])
      project.boards.each do |board|
        new_board = Board.new
        new_board.attributes = board.attributes.dup.except('id',
                                                           'project_id',
                                                           'topics_count',
                                                           'messages_count',
                                                           'last_message_id')
        copy_topics(board, new_board)

        new_board.project = self
        boards << new_board
      end
    end

    def copy_topics(board, new_board)
      topics = board.topics.where('parent_id is NULL')
      topics.each do |topic|
        new_topic = Message.new
        new_topic.attributes = topic.attributes.dup.except('id',
                                                           'board_id',
                                                           'author_id',
                                                           'replies_count',
                                                           'last_reply_id',
                                                           'created_on',
                                                           'updated_on')
        new_topic.board = new_board
        new_topic.author_id = topic.author_id
        new_board.topics << new_topic
      end
    end

    def copy_attachments(from_container, to_container)
      from_container.attachments.each do |old_attachment|
        begin
          copied = old_attachment.dup
          old_attachment.file.copy_to(copied)
          to_container.attachments << copied

          if copied.new_record?
            Rails.logger.error "Project#copy_attachments: Attachments ##{old_attachment.id} could not be copied: #{copied.errors.full_messages}"
          end
        rescue => e
          Rails.logger.error "Failed to copy attachments from #{from_container} to #{to_container}: #{e}"
        end
      end
    end
  end
end
