#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
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
        if user.active? || user.registered? || user.invited?
          link_to(name, user, options)
        else
          name
        end
      else
        h(user.to_s)
      end
    end

    def link_to_work_package_preview(context = nil, options = {})
      form_id = options[:form_id] || 'work_package-form-preview'
      path = (context.is_a? WorkPackage) ? preview_work_package_path(context) : preview_work_packages_path

      preview_link path, "#{form_id}-preview"
    end

    # Generates a link to an attachment.
    # Options:
    # * :text - Link text (default to attachment filename)
    # * :download - Force download (default: false)
    def link_to_attachment(attachment, options = {})
      text = options.delete(:text) || attachment.filename
      only_path = options.delete(:only_path) { true }

      link_to h(text),
              { controller: '/attachments',
                action: 'download',
                id: attachment,
                filename: attachment.filename,
                host: Setting.host_name,
                protocol: Setting.protocol,
                only_path: only_path },
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
        topic_path_or_url(message.root,
                          { r: (message.parent_id && message.id),
                            anchor: (message.parent_id ? "message-#{message.id}" : nil)
                          }.merge(options)),
        html_options
      )
    end

    # Generates a link to a project if active
    # Examples:
    #
    #   link_to_project(project)                          # => link to the specified project overview
    #   link_to_project(project, action:'settings')     # => link to project settings
    #   link_to_project(project, {only_path: false}, class: "project") # => 3rd arg adds html options
    #   link_to_project(project, {}, class: "project") # => html options with default url (project overview)
    #
    def link_to_project(project, options = {}, html_options = nil, show_icon = false)
      link = ''
      project_link_name = project.name

      if show_icon && User.current.member_of?(project)
        project_link_name = icon_wrapper('icon-context icon-star', I18n.t(:description_my_project).html_safe + '&nbsp;'.html_safe) + project_link_name
      end

      if project.active?
        # backwards compatibility
        if options.delete(:action) == 'settings'
          link << link_to(project_link_name, settings_project_path_or_url(project, options), html_options)
        else
          link << link_to(project_link_name, project_path_or_url(project, options), html_options)
        end
      else
        link << project_link_name
      end

      link.html_safe
    end
  end
end
