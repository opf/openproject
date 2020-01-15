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
    def link_to_user(user, options = {})
      if user.is_a?(User)
        name = user.name
        only_path = options.delete(:only_path)
        only_path = true if only_path.nil?

        if user.active? || user.registered? || user.invited?
          href = only_path ? user_path(user) : user_url(user)
          options[:title] ||= I18n.t(:label_user_named, name: name)

          link_to(name, href, options)
        else
          name
        end
      else
        h(user.to_s)
      end
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
      url_opts = { controller: '/repositories', action: 'revision', project_id: project, rev: rev }
      html_options = { title: l(:label_revision_id, format_revision(revision)) }.merge(options)
      link_to(h(text), url_opts, html_options)
    end

    # Generates a link to a message
    def link_to_message(message, options = {}, html_options = nil)
      link_to(
        h(truncate(message.subject, length: 60)),
        topic_path_or_url(options.delete(:no_root) ? message : message.root,
                          {
                            r: (message.parent_id && message.id),
                            anchor: (message.parent_id ? "message-#{message.id}" : nil)
                          }.merge(options)),
        html_options
      )
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
      end.html_safe
    end

    private

    def project_link_name(project, show_icon)
      if show_icon && User.current.member_of?(project)
        icon_wrapper('icon-context icon-star', I18n.t(:description_my_project).html_safe + '&nbsp;'.html_safe) + project.name
      else
        project.name
      end
    end

    def url_to_attachment(attachment, only_path: true)
      # Including the module breaks the application in strange and mysterious ways
      v3_paths = API::V3::Utilities::PathHelper::ApiV3Path

      if only_path
        v3_paths.attachment_content(attachment.id)
      else
        v3_paths.url_for(:attachment_content, attachment.id)
      end
    end
  end
end
