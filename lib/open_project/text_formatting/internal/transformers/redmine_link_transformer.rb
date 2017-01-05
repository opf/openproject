#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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

module OpenProject::TextFormatting::Internal::Transformers
  require 'open_project/text_formatting/internal/transformers/text_transformer.rb'

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
  #   Links can refer other objects from other work_package_css_classesprojects, using project identifier:
  #     identifier:r52
  #     identifier:document:"Some document"
  #     identifier:version:1.0.0
  #     identifier:source:some/file
  class RedmineLinkTransformer < TextTransformer
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TextHelper
    include ::OpenProject::StaticRouting::UrlHelpers
    include ::OpenProject::SimpleTextFormatting
    include ::OpenProject::ObjectLinking
    include ::WorkPackagesHelper
    include ERB::Util # for h()

    def process(fragment, **options)
      fragment.xpath('text()|*//text()').each do |node|
        do_process node, options
      end
      fragment
    end

    private

    LINK_RE =
      %r{([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-_]+):)?(attachment|version|commit|source|export|message|project)?((#+|r)(\d+)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)} unless const_defined?(:LINK_RE)

    # separator: prefix : formatter
    FORMATTER_MAP = {
      r: {
        nil: :make_link_changeset
      },
      '#'.to_sym => {
        nil: :make_link_work_package,
        version: :make_link_version,
        message: :make_link_message,
        project: :make_link_project,
      },
      '##'.to_sym => {
        nil: :make_link_work_package_info
      },
      '###': {
        nil: :make_link_work_package_desc
      },
      ':'.to_sym => {
        version: :make_link_version_by_project,
        commit: :make_link_changeset_by_name,
        source: :make_link_source_or_export,
        export: :make_link_source_or_export,
        attachment: :make_link_attachment,
        project: :make_link_project
      }
    } unless const_defined?(:FORMATTER_MAP)

    def do_process(node, options)
      text = node.text.gsub(LINK_RE) do |_m|
        leading = $1
        esc = $2
        prefix = $5
        sep = $7 || $9
        match = {
          project_prefix: $3,
          project_identifier: $4,
          identifier: $8 || $10,
          prefix: prefix # included for make_link_source_or_export
        }
        match[:oid] = match[:identifier].to_i
        if sep == ':'
          match[:name] = match[:identifier].gsub(%r{\A"(.*)"\z}, '\\1')
        end
        unless match[:project_identifier].nil?
          match[:project] = Project.visible.find_by(
            identifier: match[:project_identifier]
          )
        end
        link = nil
        if esc.nil?
          formatters = FORMATTER_MAP[sep.to_sym]
          formatter = formatters[(prefix || :nil).to_sym] unless formatters.nil?
          link = self.send(formatter, match, options) unless formatter.nil?
        end
        leading + (link || "#{match[:project_prefix]}#{prefix}#{sep}#{match[:identifier]}")
      end
      if node.text != text
        node.replace Nokogiri::XML.fragment text
      end
    end

    def make_link_changeset(match, options)
      project = match[:project] || options[:project]
      project_prefix = match[:project_prefix]
      identifier = match[:identifier]

      # project.changesets.visible raises an SQL error because
      # of a double join on repositories
      changeset = Changeset.visible.find_by(
        repository_id: project.repository.id, revision: identifier
      ) unless project.nil? || project.repository.nil?

      link_to(
        h("#{project_prefix}r#{identifier}"),
        {
          only_path: options[:only_path], controller: '/repositories',
          action: 'revision', project_id: project, rev: changeset.revision
        },
        class: 'changeset',
        title: truncate_single_line(changeset.comments, length: 100)
      ) unless changeset.nil?
    end

    def make_link_changeset_by_name(match, options)
      project = match[:project] || options[:project]
      project_prefix = match[:project_prefix]
      name = match[:name]

      # project.changesets.visible raises an SQL error because
      # of a double join on repositories
      changeset = Changeset.visible.where(
        [
          'repository_id = ? AND scmid LIKE ?',
          project.repository.id, "#{name}%"
        ]
      ).first unless project.nil? || project.repository.nil?

      link_to(
        h("#{project_prefix}#{name}"),
        {
          only_path: options[:only_path],
          controller: '/repositories',
          action: 'revision',
          project_id: project,
          rev: changeset.identifier
        },
        class: 'changeset',
        title: truncate_single_line(changeset.comments, length: 100)
      ) unless changeset.nil?
    end

    def make_link_message(match, options)
      message = Message.visible.includes(:parent).find_by(id: match[:oid])
      link_to_message(
        message, { only_path: options[:only_path] }, class: 'message'
      ) unless message.nil?
    end

    def make_link_work_package(match, options)
      oid = match[:oid]
      work_package = WorkPackage.visible
                       .includes(:status)
                       .references(:statuses)
                       .find_by(id: oid)
      link_to(
        "##{oid}",
        work_package_path_or_url(id: oid, only_path: options[:only_path]),
        class: work_package_css_classes(work_package),
        title: "#{truncate(work_package.subject, length: 100)} " +
          "(#{work_package.status.try(:name)})"
      ) unless work_package.nil?
    end

    def make_link_work_package_info(match, options)
      work_package = WorkPackage.visible
                       .includes(:status)
                       .references(:statuses)
                       .find_by(id: match[:oid])
      work_package_quick_info(
        work_package, only_path: options[:only_path]
      ) unless work_package.nil?
    end

    def make_link_work_package_desc(match, options)
      oid = match[:oid]
      obj = options[:object]
      attr = options[:attr]
      work_package = nil
      if !obj.nil? && (attr == :description && obj.id == work_package.id)
        work_package = WorkPackage.visible
                         .includes(:status)
                         .references(:statuses)
                         .find_by(id: oid)
      end
      work_package_quick_info_with_description(
        work_package, only_path: options[:only_path]
      ) unless work_package.nil?
    end

    def make_link_version(match, options)
      oid = match[:oid]
      version = Version.visible.find_by(id: oid)
      link_to(
        h(version.name),
        {
          only_path: options[:only_path],
          controller: '/versions',
          action: 'show',
          id: version
        },
        class: 'version'
      ) unless version.nil?
    end

    def make_link_version_by_project(match, options)
      project = match[:project] || options[:project]
      version = project.versions.visible.find_by(name: match[:name]) unless project.nil?
      link_to(
        h(version.name),
        {
          only_path: options[:only_path],
          controller: '/versions',
          action: 'show',
          id: version
        },
        class: 'version'
      ) unless version.nil?
    end

    # TODO:coy:refactor to multi line statement
    REV_PATH_ANCHOR_RE =
      %r{\A[/\\]*(.*?)(@([0-9a-f]+))?(#(L\d+))?\z} unless const_defined?(:REV_PATH_ANCHOR_RE)

    def make_link_source_or_export(match, options)
      project = match[:project] || options[:project]
      project_prefix = match[:project_prefix]
      prefix = match[:prefix]
      name = match[:name]
      if project && project.repository && User.current.allowed_to?(
        :browse_repository, project
      )
        name =~ REV_PATH_ANCHOR_RE
        path = $1
        rev = $3
        anchor = $5

        link_to(
          h("#{project_prefix}#{prefix}:#{name}"),
          {
            controller: '/repositories',
            action: 'entry',
            project_id: project,
            path: path.to_s,
            rev: rev,
            anchor: anchor,
            format: (prefix == 'export' ? 'raw' : nil)
          },
          class: (prefix == 'export' ? 'source download' : 'source')
        )
      else
        nil
      end
    end

    def make_link_attachment(match, options)
      attachments = determine_attachments(options)

      attachment = attachments.detect {
        |a| a.filename == match[:name]
      } unless attachments.nil?

      link_to(
        h(attachment.filename),
        {
          only_path: options[:only_path],
          controller: '/attachments',
          action: 'download',
          id: attachment
        },
        class: 'attachment'
      ) unless attachment.nil?
    end

    def determine_attachments(options)
      obj = options[:object]
      if options[:attachments]
        options[:attachments]
      elsif obj.respond_to?(:attachments)
        obj.attachments
      else
        nil
      end
    end

    def make_link_project(match, options)
      name = match[:name]
      project = Project.visible.where(
        [
          'projects.identifier = :s OR LOWER(projects.name) = :s',
          { s: name.downcase }
        ]
      ).first
      link_to_project(
        p, { only_path: options[:only_path] }, class: 'project'
      ) unless project.nil?
    end
  end
end
