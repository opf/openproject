# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module ObjectLinking
    # path helpers shim to support deprecated :only_path option
    %i(project settings_project topic work_package).each do |model|
      define_method :"#{model}_path_or_url" do |*args, options|
        if options.delete(:only_path) == false
          __send__(:"#{model}_url", *args, options)
        else
          __send__(:"#{model}_path", *args, options)
        end
      end
    end

    # Displays a link to user's account page if active or registered
    # Will attach a user hover card to the link.
    def link_to_user(user, options = {}) # rubocop:disable Metrics/AbcSize
      return content_tag(:span, h(user.to_s), class: options[:class]) unless user.is_a?(User)
      return content_tag(:span, h(user.name), class: options[:class]) if user_not_linkable?(user)

      only_path = options.delete(:only_path) { true }
      name = options.delete(:name) { user.name }
      options[:title] ||= I18n.t(:label_user_named, name:)

      add_hover_card_options(user, options, only_path:)

      link_to(name, user_url(user, only_path:), options)
    end

    # Displays a link to group's account page
    def link_to_group(group, options = {})
      return content_tag(:span, h(group.to_s), class: options[:class]) unless group.is_a?(Group)

      name = group.name
      href = show_group_url(group,
                            only_path: options.delete(:only_path) { true })
      options[:title] ||= I18n.t(:label_group_named, name:)

      link_to(name, href, options)
    end

    # Generates a link to an attachment.
    # Options:
    # * :text - Link text (default to attachment filename)
    # * :download - Force download (default: false)
    def link_to_attachment(attachment, options = {})
      text = options.delete(:text) || attachment.filename

      link_to text,
              url_to_attachment(attachment, only_path: options.delete(:only_path) { true }),
              options
    end

    # Generates a link to a SCM revision
    # Options:
    # * :text - Link text (default to the formatted revision)
    def link_to_revision(revision, project, options = {})
      text = options.delete(:text) || format_revision(revision)
      rev = revision.respond_to?(:identifier) ? revision.identifier : revision
      url_opts = { controller: "/repositories", action: "revision", project_id: project, rev: }
      html_options = { title: I18n.t(:label_revision_id, value: format_revision(revision)) }.merge(options)
      link_to(h(text), url_opts, html_options)
    end

    # Generates a link to a query
    def link_to_query(query, options = {}, html_options = nil)
      text = h(query.name)
      url = project_work_packages_url([query.project.id], only_path: options.delete(:only_path) { true }, query_id: query.id)
      link_to(text, url, html_options)
    end

    # Generates a link to a message
    def link_to_message(message, options = {}, html_options = nil) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      only_path = options.delete(:only_path)
      link = if only_path
               project_forum_topic_path(message.forum.project, message.forum, options.delete(:no_root) ? message : message.root,
                                        {
                                          r: message.parent_id && message.id,
                                          anchor: (message.parent_id ? "message-#{message.id}" : nil)
                                        }.merge(options))
             else
               project_forum_topic_url(message.forum.project, message.forum, options.delete(:no_root) ? message : message.root,
                                       {
                                         r: message.parent_id && message.id,
                                         anchor: (message.parent_id ? "message-#{message.id}" : nil)
                                       }.merge(options))
             end

      link_to(h(truncate(message.subject, length: 60)), link, html_options)
    end

    # Generates a link to a project if active
    # Examples:
    #
    #   link_to_project(project)                          # => link to the specified project overview
    #   link_to_project(project, {only_path: false}, class: "project") # => 3rd arg adds html options
    #   link_to_project(project, {}, class: "project") # => html options with default url (project overview)
    #
    def link_to_project(project, options = {}, html_options = nil, show_icon = false)
      project_name = project_link_name(project, show_icon)

      if project.active?
        link_to(project_name, project_path_or_url(project, options), html_options)
      else
        project_name
      end
    end

    # Like #link_to_user, but will render a Primer link instead of a regular link.
    def primer_link_to_user(user, options = {})
      options[:href] ||= user_path(user)
      options[:target] ||= "_blank"
      options[:underline] ||= false

      options = add_hover_card_options(user, options)

      render Primer::Beta::Link.new(**options) do
        user.name
      end
    end

    private

    # Accepts a user and an options hash. Will apply a hover card config for the user to the options hash.
    # Will not do anything if `hover_card` is set to false within the options.
    # You can use this method if you want to render a link and apply a user hover card to it.
    def add_hover_card_options(user, options, only_path: true)
      if options.delete(:hover_card) { true } && user.is_a?(User)
        options[:data] ||= {}

        hover_card_url = hover_card_user_url(user, only_path:)
        options[:data][:hover_card_url] = hover_card_url
        options[:data][:hover_card_trigger_target] = "trigger"
      end

      options
    end

    def project_link_name(project, show_icon)
      if show_icon && User.current.member_of?(project)
        label = ActiveSupport::SafeBuffer.new
        label << I18n.t(:description_my_project)
        label << "&nbsp;".html_safe

        icon_wrapper("icon-context icon-star", label) + project.name
      else
        project.name
      end
    end

    def url_to_attachment(attachment, only_path: true)
      if only_path
        v3_paths.attachment_content(attachment.id)
      else
        v3_paths.url_for(:attachment_content, attachment.id)
      end
    end

    def url_to_file_link(file_link, only_path: true)
      if only_path
        v3_paths.file_link_open(file_link.id)
      else
        v3_paths.url_for(:file_link_open, file_link.id)
      end
    end

    def v3_paths
      # Including the module breaks the application in strange and mysterious ways
      API::V3::Utilities::PathHelper::ApiV3Path
    end

    def user_not_linkable?(user)
      (user.locked? || user.deleted?) && !User.current.admin?
    end
  end
end
