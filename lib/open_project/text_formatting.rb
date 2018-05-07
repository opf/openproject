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
  module TextFormatting
    extend ActiveSupport::Concern
    extend DeprecatedAlias

    include Redmine::WikiFormatting::Macros::Definitions
    include ActionView::Helpers::SanitizeHelper
    include ERB::Util # for h()
    include Redmine::I18n
    include ActionView::Helpers::TextHelper
    include OpenProject::ObjectLinking
    include OpenProject::SafeParams
    # The WorkPackagesHelper is required to get access to the methods
    # 'work_package_css_classes' and 'work_package_quick_info'.
    include WorkPackagesHelper

    # Truncates and returns the string as a single line
    def truncate_single_line(string, *args)
      truncate(string.to_s, *args).gsub(%r{[\r\n]+}m, ' ').html_safe
    end

    # Truncates at line break after 250 characters or options[:length]
    def truncate_lines(string, options = {})
      length = options[:length] || 250
      if string.to_s =~ /\A(.{#{length}}.*?)$/m
        "#{$1}..."
      else
        string
      end
    end

    # Formats text according to system settings.
    # 2 ways to call this method:
    # * with a String: format_text(text, options)
    # * with an object and one of its attribute: format_text(issue, :description, options)
    def format_text(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      case args.size
      when 1
        obj = options[:object]
        text = args.shift
      when 2
        obj = args.shift
        attr = args.shift
        text = obj.send(attr).to_s
      else
        raise ArgumentError, 'invalid arguments to format_text'
      end
      return '' if text.blank?

      edit = !!options[:edit]
      # don't return html in edit mode when textile or text formatting is enabled
      return text if edit
      project = options[:project] || @project || (obj && obj.respond_to?(:project) ? obj.project : nil)
      only_path = options.delete(:only_path) != false

      # offer 'plain' as readable version for 'no formatting' to callers
      options_format = options[:format] == 'plain' ? '' : options[:format]
      format = options_format || Setting.text_formatting
      text = Redmine::WikiFormatting.to_html(format, text,
                                             object: obj,
                                             attribute: attr,
                                             edit: edit)
      # TODO: transform modifications into WikiFormatting Helper, or at least ask the helper if he wants his stuff to be modified
      @parsed_headings = []
      text = parse_non_pre_blocks(text) { |text|
        [:execute_macros, :parse_inline_attachments, :parse_wiki_links, :parse_redmine_links, :parse_headings, :parse_relative_urls].each do |method_name|
          send method_name, text, project, obj, attr, only_path, options
        end
      }

      if @parsed_headings.any?
        replace_toc(text, @parsed_headings)
      end

      escape_non_macros(text)
      text.html_safe
    end
    deprecated_alias :textilizable, :format_text
    deprecated_alias :textilize,    :format_text

    ##
    # Escape double curly braces after macro expansion.
    # This will avoid arbitrary angular expressions to be evaluated in
    # formatted text marked html_safe.
    def escape_non_macros(text)
      text.gsub!(/\{\{(?! \$root\.DOUBLE_LEFT_CURLY_BRACE)/, '{{ $root.DOUBLE_LEFT_CURLY_BRACE }}')
    end

    def parse_non_pre_blocks(text)
      s = StringScanner.new(text)
      tags = []
      parsed = ''
      while !s.eos?
        s.scan(/(.*?)(<(\/)?(pre|code)(.*?)>|\z)/im)
        text = s[1]
        full_tag = s[2]
        closing = s[3]
        tag = s[4]
        if tags.empty?
          yield text
        end
        parsed << text
        if tag
          if closing
            if tags.last == tag.downcase
              tags.pop
            end
          else
            tags << tag.downcase
          end
          parsed << full_tag
        end
      end
      # Close any non closing tags
      while tag = tags.pop
        parsed << "</#{tag}>"
      end
      parsed
    end


    MACROS_RE = /
                  (!)?                        # escaping
                  (
                  \{\{                        # opening tag
                  ([\w]+)                     # macro name
                  (\(([^\}]*)\))?             # optional arguments
                  \}\}                        # closing tag
                  )
                /x unless const_defined?(:MACROS_RE)

    # Macros substitution
    def execute_macros(text, project, obj, _attr, _only_path, options)
      return if !!options[:edit]
      text.gsub!(MACROS_RE) do
        esc = $1
        all = $2
        macro = $3
        args = ($5 || '').split(',').each(&:strip!)
        if esc.nil?
          begin
            exec_macro(macro, obj, args, view: self, project: project)
          rescue => e
            "<span class=\"flash error macro-unavailable permanent\">\
            #{::I18n.t(:macro_execution_error, macro_name: macro)} (#{e})\
            </span>".squish
          rescue NotImplementedError
            "<span class=\"flash error macro-unavailable permanent\">\
            #{::I18n.t(:macro_unavailable, macro_name: macro)}\
            </span>".squish
          end || all
        else
          all
        end
      end
    end

    RELATIVE_LINK_RE = %r{
      <a
      (?:
        (\shref=
          (?:                         # the href and link
            (?:'(\/[^>]+?)')|
            (?:"(\/[^>]+?)")
          )
        )|
        [^>]
      )*
      >
      [^<]*?<\/a>                     # content and closing link tag.
    }x unless const_defined?(:RELATIVE_LINK_RE)

    def parse_relative_urls(text, _project, _obj, _attr, only_path, _options)
      return if only_path
      text.gsub!(RELATIVE_LINK_RE) do |m|
        href = $1
        relative_url = $2 || $3
        next m unless href.present?
        if defined?(request) && request.present?
          # we have a request!
          protocol = request.protocol
          host_with_port = request.host_with_port
        elsif @controller
          # use the same methods as url_for in the Mailer
          url_opts = @controller.class.default_url_options
          next m unless url_opts && url_opts[:protocol] && url_opts[:host]
          protocol = "#{url_opts[:protocol]}://"
          host_with_port = url_opts[:host]
        else
          next m
        end
        m.sub href, " href=\"#{protocol}#{host_with_port}#{relative_url}\""
      end
    end

    def parse_inline_attachments(text, _project, obj, _attr, only_path, options)
      # when using an image link, try to use an attachment, if possible
      if options[:attachments] || (obj && obj.respond_to?(:attachments))
        attachments = nil
        text.gsub!(/src="([^\/"]+\.(bmp|gif|jpg|jpeg|png|svg))"(\s+alt="([^"]*)")?/i) do |m|
          filename = $1.downcase
          ext = $2
          alt = $3
          alttext = $4
          attachments ||= (options[:attachments] || obj.attachments).sort_by(&:created_on).reverse
          # search for the picture in attachments
          if found = attachments.detect { |att| att.filename.downcase == filename }
            image_url = url_for only_path: only_path, controller: '/attachments', action: 'download', id: found
            desc = found.description.to_s.gsub('"', '')
            if !desc.blank? && alttext.blank?
              alt = " title=\"#{desc}\" alt=\"#{desc}\""
            end
            "src=\"#{image_url}\"#{alt}"
          else
            m
          end
        end
      end
    end

    # Wiki links
    #
    # Examples:
    #   [[mypage]]
    #   [[mypage|mytext]]
    # wiki links can refer other project wikis, using project name or identifier:
    #   [[project:]] -> wiki starting page
    #   [[project:|mytext]]
    #   [[project:mypage]]
    #   [[project:mypage|mytext]]
    def parse_wiki_links(text, project, _obj, _attr, only_path, options)
      text.gsub!(/(!)?(\[\[([^\]\n\|]+)(\|([^\]\n\|]+))?\]\])/) do |_m|
        link_project = project
        esc = $1
        all = $2
        page = $3
        title = $5
        if esc.nil?
          if page =~ /\A([^\:]+)\:(.*)\z/
            link_project = Project.find_by(identifier: $1) || Project.find_by(name: $1)
            page = $2
            title ||= $1 if page.blank?
          end

          if link_project && link_project.wiki
            # extract anchor
            anchor = nil
            if page =~ /\A(.+?)\#(.+)\z/
              page = $1
              anchor = $2
            end
            # Unescape the escaped entities from textile
            page = CGI.unescapeHTML(page)
            # check if page exists
            wiki_page = link_project.wiki.find_page(page)
            default_wiki_title = wiki_page.nil? ? page : wiki_page.title
            wiki_title = title || default_wiki_title
            url = case options[:wiki_links]
                  when :local; "#{title}.html"
                  when :anchor; "##{title}"   # used for single-file wiki export
                  else
                    wiki_page_id = wiki_page.nil? ? page.to_url : wiki_page.slug
                    url_for(only_path: only_path,
                            controller: '/wiki',
                            action: 'show',
                            project_id: link_project,
                            id: wiki_page_id,
                            title: wiki_page.nil? ? wiki_title.strip : nil,
                            anchor: anchor)
              end
            link_to(h(wiki_title), url, class: ('wiki-page' + (wiki_page ? '' : ' new')))
          else
            # project or wiki doesn't exist
            all
          end
        else
          all
        end
      end
    end

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
    def parse_redmine_links(text, project, obj, attr, only_path, options)
      text.gsub!(%r{([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-_]+):)?(attachment|version|commit|source|export|message|project|user)?((#+|r)(\d+)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)}) do |_m|
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
            when 'user'
              if user = User.in_visible_project.find_by(id: oid)
                link = link_to_user(user, class: 'user-mention')
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
            when 'user'
              if user = User.in_visible_project.find_by(login: name)
                link = link_to_user(user, class: 'user-mention')
              end
            end
          end
        end
        leading + (link || "#{project_prefix}#{prefix}#{sep}#{identifier}")
      end
    end

    HEADING_RE = /<h(1|2|3|4)( [^>]+)?>(.+?)<\/h(1|2|3|4)>/i unless const_defined?(:HEADING_RE)

    # Headings and TOC
    # Adds ids and links to headings unless options[:headings] is set to false
    def parse_headings(text, _project, _obj, _attr, _only_path, options)
      return if options[:headings] == false

      text.gsub!(HEADING_RE) do
        level = $1.to_i
        attrs = $2
        content = $3
        item = strip_tags(content).strip
        tocitem = strip_tags(content.gsub(/<br \/>/, ' '))
        anchor = item.gsub(%r{[^\w\s\-]}, '').gsub(%r{\s+(\-+\s*)?}, '-')
        @parsed_headings << [level, anchor, tocitem]
        url = full_url(anchor)
        "<a name=\"#{anchor}\"></a>\n<h#{level} #{attrs}>#{content}<a href=\"#{url}\" class=\"wiki-anchor\">&para;</a></h#{level}>"
      end
    end

    TOC_RE = /<p>\{\{([<>]?)toc\}\}<\/p>/i unless const_defined?(:TOC_RE)

    # Renders the TOC with given headings
    def replace_toc(text, headings)
      text.gsub!(TOC_RE) do
        if headings.empty?
          ''
        else
          div_class = 'toc'
          div_class << ' right' if $1 == '>'
          div_class << ' left' if $1 == '<'
          out = "<fieldset class='form--fieldset -collapsible'>"
          out << "<legend class='form--fieldset-legend' title='" +
            l(:description_toc_toggle) +
            "' onclick='toggleFieldset(this);'>
            <a href='javascript:'>
              #{l(:label_table_of_contents)}
            </a>
            </legend><div>"
          out << "<ul class=\"#{div_class}\"><li>"
          root = headings.map(&:first).min
          current = root
          started = false
          headings.each do |level, anchor, item|
            if level > current
              out << '<ul><li>' * (level - current)
            elsif level < current
              out << "</li></ul>\n" * (current - level) + '</li><li>'
            elsif started
              out << '</li><li>'
            end
            url = full_url anchor
            out << "<a href=\"#{url}\">#{item}</a>"
            current = level
            started = true
          end
          out << '</li></ul>' * (current - root)
          out << '</li></ul>'
          out << '</div></fieldset>'
        end
      end
    end

    #
    # displays the current url plus an optional anchor
    #
    def full_url(anchor_name = '')
      return "##{anchor_name}" if current_request.nil?
      url_for pagination_params_whitelist.merge(anchor: anchor_name, only_path: true)
    rescue ActionController::UrlGenerationError
      # In a context outside params, we don't know what the relative anchor url is
      "##{anchor_name}"
    end

    def current_request
      request rescue nil
    end
  end
end
