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

module OpenProject
  module TextFormatting
    module Transformers
      # Redmine links
      #
      # Examples:
      #   Issues:
      #     #52 -> Link to issue #52
      #   Changesets:
      #     r52 -> Link to revision 52
      #     commit:a85130f -> Link to scmid starting with a85130f
      #   Documents:
      #     document#17 -> Link to document with id 17
      #     document:Greetings -> Link to the document with title "Greetings"
      #     document:"Some document" -> Link to the document with title "Some document"
      #   Versions:
      #     version#3 -> Link to version with id 3
      #     version:1.0.0 -> Link to version named "1.0.0"
      #     version:"1.0 beta 2" -> Link to version named "1.0 beta 2"
      #   Attachments:
      #     attachment:file.zip -> Link to the attachment of the current object named file.zip
      #   Source files:
      #     source:some/file -> Link to the file located at /some/file in the project's repository
      #     source:some/file@52 -> Link to the file's revision 52
      #     source:some/file#L120 -> Link to line 120 of the file
      #     source:some/file@52#L120 -> Link to line 120 of the file's revision 52
      #     export:some/file -> Force the download of the file
      #   Forum messages:
      #     message#1218 -> Link to message with id 1218
      #
      #   Links can refer other objects from other projects, using project identifier:
      #     identifier:r52
      #     identifier:document:"Some document"
      #     identifier:version:1.0.0
      #     identifier:source:some/file
      class RedmineLinkTransformer < TextTransformer
        def process(fragment, options)
          result = Nokogiri::XML.fragment ''
          fragment.children.each do |node|
            if node.text?
              project = options[:project]
              obj = options[:object]
              attr = options[:attr]
              only_path = options[:only_path]
              text = node.to_s.gsub(%r{([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-_]+):)?(attachment|version|commit|source|export|message|project)?((#+|r)(\d+)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)}) do |_m|
                leading = $1
                esc = $2
                project_prefix = $3
                project_identifier = $4
                prefix = $5
                sep = $7 || $9
                identifier = $8 || $10
                link = nil
                if project_identifier
                  project = Project.visible.find_by(identifier: project_identifier)
                end
                if esc.nil?
                  if prefix.nil? && sep == 'r'
                    # project.changesets.visible raises an SQL error because of a double join on repositories
                    if project && project.repository && (changeset = Changeset.visible.find_by(repository_id: project.repository.id, revision: identifier))
                      link = link_to(h("#{project_prefix}r#{identifier}"), { only_path: only_path, controller: '/repositories', action: 'revision', project_id: project, rev: changeset.revision },
                                     class: 'changeset',
                                     title: truncate_single_line(changeset.comments, length: 100))
                    end
                  elsif sep == '#'
                    oid = identifier.to_i
                    case prefix
                      when nil
                        if work_package = WorkPackage.visible
                                            .includes(:status)
                                            .references(:statuses)
                                            .find_by(id: oid)
                          link = link_to("##{oid}",
                                         work_package_path_or_url(id: oid, only_path: only_path),
                                         class: work_package_css_classes(work_package),
                                         title: "#{truncate(work_package.subject, length: 100)} (#{work_package.status.try(:name)})")
                        end
                      when 'version'
                        if version = Version.visible.find_by(id: oid)
                          link = link_to h(version.name), { only_path: only_path, controller: '/versions', action: 'show', id: version },
                                         class: 'version'
                        end
                      when 'message'
                        if message = Message.visible.includes(:parent).find_by(id: oid)
                          link = link_to_message(message, { only_path: only_path }, class: 'message')
                        end
                      when 'project'
                        if p = Project.visible.find_by(id: oid)
                          link = link_to_project(p, { only_path: only_path }, class: 'project')
                        end
                    end
                  elsif sep == '##'
                    oid = identifier.to_i
                    if work_package = WorkPackage.visible
                                        .includes(:status)
                                        .references(:statuses)
                                        .find_by(id: oid)
                      link = work_package_quick_info(work_package, only_path: only_path)
                    end
                  elsif sep == '###'
                    oid = identifier.to_i
                    work_package = WorkPackage.visible
                                     .includes(:status)
                                     .references(:statuses)
                                     .find_by(id: oid)
                    if work_package && obj && !(attr == :description && obj.id == work_package.id)
                      link = work_package_quick_info_with_description(work_package, only_path: only_path)
                    end
                  elsif sep == ':'
                    # removes the double quotes if any
                    name = identifier.gsub(%r{\A"(.*)"\z}, '\\1')
                    case prefix
                    when 'version'
                      if project && version = project.versions.visible.find_by(name: name)
                        link = link_to h(version.name), { only_path: only_path, controller: '/versions', action: 'show', id: version },
                                       class: 'version'
                      end
                    when 'commit'
                      if project && project.repository && (changeset = Changeset.visible.where(['repository_id = ? AND scmid LIKE ?', project.repository.id, "#{name}%"]).first)
                        link = link_to h("#{project_prefix}#{name}"), { only_path: only_path, controller: '/repositories', action: 'revision', project_id: project, rev: changeset.identifier },
                                       class: 'changeset',
                                       title: truncate_single_line(changeset.comments, length: 100)
                      end
                    when 'source', 'export'
                      if project && project.repository && User.current.allowed_to?(:browse_repository, project)
                        name =~ %r{\A[/\\]*(.*?)(@([0-9a-f]+))?(#(L\d+))?\z}
                        path = $1
                        rev = $3
                        anchor = $5
                        link = link_to h("#{project_prefix}#{prefix}:#{name}"), { controller: '/repositories', action: 'entry', project_id: project,
                                                                                  path: path.to_s,
                                                                                  rev: rev,
                                                                                  anchor: anchor,
                                                                                  format: (prefix == 'export' ? 'raw' : nil) },
                                       class: (prefix == 'export' ? 'source download' : 'source')
                      end
                    when 'attachment'
                      attachments = options[:attachments] || (obj && obj.respond_to?(:attachments) ? obj.attachments : nil)
                      if attachments && attachment = attachments.detect { |a| a.filename == name }
                        link = link_to h(attachment.filename), { only_path: only_path, controller: '/attachments', action: 'download', id: attachment },
                                       class: 'attachment'
                      end
                    when 'project'
                      p = Project
                            .visible
                            .where(['projects.identifier = :s OR LOWER(projects.name) = :s',
                                    { s: name.downcase }])
                            .first
                      if p
                        link = link_to_project(p, { only_path: only_path }, class: 'project')
                      end
                    end
                  end
                end
                leading + (link || "#{project_prefix}#{prefix}#{sep}#{identifier}")
              end
              result.add_child Nokogiri::XML.fragment text
            else
              result.add_child node
            end
            # TODO:coy return statement required why?
            return result
          end
        end
      end
    end
  end
end
