#-- encoding: UTF-8

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

module Projects::Copy
  def self.included(base)
    base.send :include, CopyModel
    base.send :include, self::CopyMethods

    # things that are explicitly excluded when copying a project
    base.not_to_copy ['id', 'created_at', 'updated_at', 'name', 'identifier', 'active', 'lft', 'rgt']

    # specify the order of associations to copy
    base.copy_precedence ['members', 'versions', 'categories', 'work_packages', 'wiki', 'custom_values', 'queries']
  end

  module CopyMethods
    def copy_attributes(project)
      super
      with_model(project) do |project_instance|
        # Clear enabled modules
        self.enabled_modules = []
        self.enabled_module_names = project_instance.enabled_module_names - %w[repository]
        self.types = project_instance.types
        self.work_package_custom_fields = project_instance.work_package_custom_fields
        self.custom_field_values = project_instance.custom_value_attributes
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
    def copy_custom_values(project, _selected_copies = [])
      self.custom_values = project.custom_values.map(&:dup)
    end

    # Copies wiki from +project+
    def copy_wiki(project, selected_copies = [])
      # Check that the source project has a wiki first
      unless project.wiki.nil?
        self.wiki = build_wiki(project.wiki.attributes.dup.except('id', 'project_id'))
        wiki.wiki_menu_items.delete_all
        copy_wiki_pages(project, selected_copies)
        copy_wiki_menu_items(project, selected_copies)
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
        wiki_pages_map[page] = new_wiki_page
      end
      wiki.save

      # Reproduce page hierarchy
      project.wiki.pages.each do |page|
        if page.parent_id && wiki_pages_map[page]
          wiki_pages_map[page].parent = wiki_pages_map[page.parent]
          wiki_pages_map[page].save
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
    def copy_wiki_menu_items(project, _selected_copies = [])
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
    def copy_versions(project, _selected_copies = [])
      project.versions.each do |version|
        new_version = Version.new
        new_version.attributes = version.attributes.dup.except('id', 'project_id', 'created_on', 'updated_at')
        versions << new_version
      end
    end

    # Copies issue categories from +project+
    def copy_categories(project, _selected_copies = [])
      project.categories.each do |category|
        new_category = Category.new
        new_category.send(:assign_attributes, category.attributes.dup.except('id', 'project_id'))
        categories << new_category
      end
    end

    # Copies work_packages from +project+
    def copy_work_packages(project, selected_copies = [])
      # Stores the source work_package id as a key and the copied work_packages as the
      # value.  Used to map the two together for work_package relations.
      work_packages_map = {}

      # Get work_packages sorted by their depth in the hierarchy tree
      # so that parents get copied before their children.
      to_copy = project
                .work_packages
                .includes(:custom_values, :version, :assigned_to, :responsible)
                .order_by_ancestors('asc')
                .order('id ASC')

      user_cf_ids = WorkPackageCustomField.where(field_format: 'user').pluck(:id)

      to_copy.each do |wp|
        parent_id = work_packages_map[wp.parent_id]&.id || wp.parent_id

        new_wp = copy_work_package(wp, parent_id, user_cf_ids)

        work_packages_map[wp.id] = new_wp if new_wp
      end

      # reload all work_packages in our map, they might be modified by movement in their tree
      work_packages_map.each_value(&:reload)

      # Relations and attachments after in case work_packages related each other
      to_copy.each do |wp|
        new_wp = work_packages_map[wp.id]
        unless new_wp
          # work_package was not copied
          next
        end

        # Attachments
        if selected_copies.include? :work_package_attachments
          copy_attachments(wp, new_wp)
        end

        # Relations
        wp.relations_to.non_hierarchy.direct.each do |source_relation|
          new_relation = Relation.new
          new_relation.attributes = source_relation.attributes.dup.except('id', 'from_id', 'to_id', 'relation_type')
          new_relation.to = work_packages_map[source_relation.to_id]
          if new_relation.to.nil? && Setting.cross_project_work_package_relations?
            new_relation.to = source_relation.to
          end
          new_relation.from = new_wp
          new_relation.save
        end

        wp.relations_from.non_hierarchy.direct.each do |source_relation|
          new_relation = Relation.new
          new_relation.attributes = source_relation.attributes.dup.except('id', 'from_id', 'to_id', 'relation_type')
          new_relation.from = work_packages_map[source_relation.from_id]
          if new_relation.from.nil? && Setting.cross_project_work_package_relations?
            new_relation.from = source_relation.from
          end
          new_relation.to = new_wp
          new_relation.save
        end
      end
    end

    # Copies members from +project+
    def copy_members(project, _selected_copies = [])
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
    # Only includes the queries visible in the wp table view.
    def copy_queries(project, _selected_copies = [])
      project.queries.non_hidden.includes(:query_menu_item).each do |query|
        new_query = duplicate_query(query)
        duplicate_query_menu_item(query, new_query)
      end

      # Update the context in the new project, otherwise, the filters will be invalid
      queries.map(&:set_context)
    end

    # Copies forums from +project+
    def copy_forums(project, _selected_copies = [])
      project.forums.each do |forum|
        new_forum = Forum.new
        new_forum.attributes = forum.attributes.dup.except('id',
                                                           'project_id',
                                                           'topics_count',
                                                           'messages_count',
                                                           'last_message_id')
        copy_topics(forum, new_forum)

        new_forum.project = self
        forums << new_forum
      end
    end

    def copy_topics(board, new_forum)
      topics = board.topics.where('parent_id is NULL')
      topics.each do |topic|
        new_topic = Message.new
        new_topic.attributes = topic.attributes.dup.except('id',
                                                           'forum_id',
                                                           'author_id',
                                                           'replies_count',
                                                           'last_reply_id',
                                                           'created_on',
                                                           'updated_on')
        new_topic.forum = new_forum
        new_topic.author_id = topic.author_id
        new_forum.topics << new_topic
      end
    end

    def copy_attachments(from_container, to_container)
      from_container.attachments.each do |old_attachment|
        copied = old_attachment.dup
        old_attachment.file.copy_to(copied)
        to_container.attachments << copied

        if copied.new_record?
          log_error <<~MSG
            Project#copy_attachments: Attachments ##{old_attachment.id} could not be copied: #{copied.errors.full_messages}
          MSG
        end
      rescue StandardError => e
        log_error("Failed to copy attachments from #{from_container} to #{to_container}: #{e}")
      end
    end

    def duplicate_query(query)
      new_query = ::Query.new name: '_'
      new_query.attributes = query.attributes.dup.except('id', 'project_id', 'sort_criteria')
      new_query.sort_criteria = query.sort_criteria if query.sort_criteria
      new_query.set_context
      new_query.project = self
      queries << new_query

      new_query
    end

    def duplicate_query_menu_item(source, sink)
      if source.query_menu_item && sink.persisted?
        ::MenuItems::QueryMenuItem.create(
          navigatable_id: sink.id,
          name: SecureRandom.uuid,
          title: source.query_menu_item.title
        )
      end
    end

    def copy_work_package(source_work_package, parent_id, user_cf_ids)
      overrides = copy_work_package_attribute_overrides(source_work_package, parent_id, user_cf_ids)

      service_call = WorkPackages::CopyService
                     .new(user: User.current,
                          work_package: source_work_package,
                          contract_class: WorkPackages::CopyProjectContract)
                     .call(overrides)

      if service_call.success?
        service_call.result
      elsif logger&.info
        log_work_package_copy_error(source_work_package, service_call.errors)
      end
    end

    def copy_work_package_attribute_overrides(source_work_package, parent_id, user_cf_ids)
      custom_value_attributes = source_work_package.custom_value_attributes.map do |id, value|
        if user_cf_ids.include?(id) && !users.detect { |u| u.id.to_s == value }
          [id, nil]
        else
          [id, value]
        end
      end.to_h

      {
        project: self,
        parent_id: parent_id,
        version: work_package_version(source_work_package),
        assigned_to: work_package_assigned_to(source_work_package),
        responsible: work_package_responsible(source_work_package),
        custom_field_values: custom_value_attributes,
        # We fetch the value from the global registry to persist it in the job which
        # will trigger a delayed job for potentially sending the journal notifications.
        send_notifications: ActionMailer::Base.perform_deliveries
      }
    end

    def work_package_version(source_work_package)
      source_work_package.version && versions.detect { |v| v.name == source_work_package.version.name }
    end

    def work_package_assigned_to(source_work_package)
      source_work_package.assigned_to && possible_assignees.detect { |u| u.id == source_work_package.assigned_to_id }
    end

    def work_package_responsible(source_work_package)
      source_work_package.responsible && possible_responsibles.detect { |u| u.id == source_work_package.responsible_id }
    end

    def log_work_package_copy_error(source_work_package, errors)
      compiled_errors << errors
      message = <<-MSG
          Project#copy_work_packages: work package ##{source_work_package.id} could not be copied: #{errors.full_messages}
      MSG

      log_error(message, :info)
    end

    def log_error(message, level = :error)
      Rails.logger.send(level, message)
    end
  end
end
