#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'forwardable'
require 'cgi'

module ApplicationHelper
  include Redmine::WikiFormatting::Macros::Definitions
  include Redmine::I18n
  include GravatarHelper::PublicMethods

  extend Forwardable
  def_delegators :wiki_helper, :wikitoolbar_for, :heads_for_wiki_formatter

  # Return true if user is authorized for controller/action, otherwise false
  def authorize_for(controller, action)
    User.current.allowed_to?({:controller => controller, :action => action}, @project)
  end

  # Display a link if user is authorized
  #
  # @param [String] name Anchor text (passed to link_to)
  # @param [Hash] options Hash params. This will checked by authorize_for to see if the user is authorized
  # @param [optional, Hash] html_options Options passed to link_to
  # @param [optional, Hash] parameters_for_method_reference Extra parameters for link_to
  def link_to_if_authorized(name, options = {}, html_options = nil, *parameters_for_method_reference)
    link_to(name, options, html_options, *parameters_for_method_reference) if authorize_for(options[:controller] || params[:controller], options[:action])
  end

  # Display a link to remote if user is authorized
  def link_to_remote_if_authorized(name, options = {}, html_options = nil)
    url = options[:url] || {}
    link_to_remote(name, options, html_options) if authorize_for(url[:controller] || params[:controller], url[:action])
  end

  # Displays a link to user's account page if active
  def link_to_user(user, options={})
    if user.is_a?(User)
      name = h(user.name(options[:format]))
      if user.active?
        link_to name, :controller => 'users', :action => 'show', :id => user
      else
        name
      end
    else
      h(user.to_s)
    end
  end

  # Show a sorted linkified (if active) comma-joined list of users
  def list_users(users, options={})
    users.sort.collect{|u| link_to_user(u, options)}.join(", ")
  end

  # Displays a link to +issue+ with its subject.
  # Examples:
  #
  #   link_to_issue(issue)                        # => Defect #6: This is the subject
  #   link_to_issue(issue, :truncate => 6)        # => Defect #6: This i...
  #   link_to_issue(issue, :subject => false)     # => Defect #6
  #   link_to_issue(issue, :project => true)      # => Foo - Defect #6
  #
  def link_to_issue(issue, options={})
    title = nil
    subject = nil
    if options[:subject] == false
      title = truncate(issue.subject, :length => 60)
    else
      subject = issue.subject
      if options[:truncate]
        subject = truncate(subject, :length => options[:truncate])
      end
    end
    s = link_to "#{h(issue.tracker)} ##{issue.id}", {:controller => "issues", :action => "show", :id => issue},
                                                 :class => issue.css_classes,
                                                 :title => title
    s << ": #{h subject}" if subject
    s = "#{h issue.project} - " + s if options[:project]
    s
  end

  # Generates a link to an attachment.
  # Options:
  # * :text - Link text (default to attachment filename)
  # * :download - Force download (default: false)
  def link_to_attachment(attachment, options={})
    text = options.delete(:text) || attachment.filename
    action = options.delete(:download) ? 'download' : 'show'

    link_to(h(text), {:controller => 'attachments', :action => action, :id => attachment, :filename => attachment.filename }, options)
  end

  # Generates a link to a SCM revision
  # Options:
  # * :text - Link text (default to the formatted revision)
  def link_to_revision(revision, project, options={})
    text = options.delete(:text) || format_revision(revision)
    rev = revision.respond_to?(:identifier) ? revision.identifier : revision

    link_to(h(text), {:controller => 'repositories', :action => 'revision', :id => project, :rev => rev},
            :title => l(:label_revision_id, format_revision(revision)))
  end

  # Generates a link to a message
  def link_to_message(message, options={}, html_options = nil)
    link_to(
      h(truncate(message.subject, :length => 60)),
      { :controller => 'messages', :action => 'show',
        :board_id => message.board_id,
        :id => message.root,
        :r => (message.parent_id && message.id),
        :anchor => (message.parent_id ? "message-#{message.id}" : nil)
      }.merge(options),
      html_options
    )
  end

  # Generates a link to a project if active
  # Examples:
  #
  #   link_to_project(project)                          # => link to the specified project overview
  #   link_to_project(project, :action=>'settings')     # => link to project settings
  #   link_to_project(project, {:only_path => false}, :class => "project") # => 3rd arg adds html options
  #   link_to_project(project, {}, :class => "project") # => html options with default url (project overview)
  #
  def link_to_project(project, options={}, html_options = nil)
    if project.active?
      url = {:controller => 'projects', :action => 'show', :id => project}.merge(options)
      link_to(h(project), url, html_options)
    else
      h(project)
    end
  end

  def toggle_link(name, id, options={})
    onclick = "Element.toggle('#{id}'); "
    onclick << (options[:focus] ? "Form.Element.focus('#{options[:focus]}'); " : "this.blur(); ")
    onclick << "return false;"
    link_to(name, "#", :onclick => onclick)
  end

  def image_to_function(name, function, html_options = {})
    html_options.symbolize_keys!
    tag(:input, html_options.merge({
        :type => "image", :src => image_path(name),
        :onclick => (html_options[:onclick] ? "#{html_options[:onclick]}; " : "") + "#{function};"
        }))
  end

  def prompt_to_remote(name, text, param, url, html_options = {})
    html_options[:onclick] = "promptToRemote('#{text}', '#{param}', '#{url_for(url)}'); return false;"
    link_to name, {}, html_options
  end

  def format_activity_title(text)
    h(truncate_single_line(text, :length => 100))
  end

  def format_activity_day(date)
    date == Date.today ? l(:label_today).titleize : format_date(date)
  end

  def format_activity_description(text)
    h(truncate(text.to_s, :length => 120).gsub(%r{[\r\n]*<(pre|code)>.*$}m, '...')).gsub(/[\r\n]+/, "<br />")
  end

  def format_version_name(version)
    if version.project == @project
    	h(version)
    else
      h("#{version.project} - #{version}")
    end
  end

  def due_date_distance_in_words(date)
    if date
      l((date < Date.today ? :label_roadmap_overdue : :label_roadmap_due_in), distance_of_date_in_words(Date.today, date))
    end
  end

  def render_page_hierarchy(pages, node=nil, options={})
    content = ''
    if pages[node]
      content << "<ul class=\"pages-hierarchy\">\n"
      pages[node].each do |page|
        content << "<li>"
        content << link_to(h(page.pretty_title), {:controller => 'wiki', :action => 'show', :project_id => page.project, :id => page.title},
                           :title => (options[:timestamp] && page.updated_on ? l(:label_updated_time, distance_of_time_in_words(Time.now, page.updated_on)) : nil))
        content << "\n" + render_page_hierarchy(pages, page.id, options) if pages[page.id]
        content << "</li>\n"
      end
      content << "</ul>\n"
    end
    content
  end

  # Renders flash messages
  def render_flash_messages
    s = ''
    flash.each do |k,v|
      s << content_tag('div', v, :class => "flash #{k}")
    end
    s
  end

  # Renders tabs and their content
  def render_tabs(tabs)
    if tabs.any?
      render :partial => 'common/tabs', :locals => {:tabs => tabs}
    else
      content_tag 'p', l(:label_no_data), :class => "nodata"
    end
  end

  # Renders the project quick-jump box
  def render_project_jump_box
    projects = User.current.memberships.collect(&:project).compact.uniq
    if projects.any?
      s = '<select onchange="if (this.value != \'\') { window.location = this.value; }">' +
            "<option value=''>#{ l(:label_jump_to_a_project) }</option>" +
            '<option value="" disabled="disabled">---</option>'
      s << project_tree_options_for_select(projects, :selected => @project) do |p|
        { :value => url_for(:controller => 'projects', :action => 'show', :id => p, :jump => current_menu_item) }
      end
      s << '</select>'
      s
    end
  end

  def project_tree_options_for_select(projects, options = {})
    s = ''
    project_tree(projects) do |project, level|
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
      tag_options = {:value => project.id}
      if project == options[:selected] || (options[:selected].respond_to?(:include?) && options[:selected].include?(project))
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end
      tag_options.merge!(yield(project)) if block_given?
      s << content_tag('option', name_prefix + h(project), tag_options)
    end
    s
  end

  # Yields the given block for each project with its level in the tree
  #
  # Wrapper for Project#project_tree
  def project_tree(projects, &block)
    Project.project_tree(projects, &block)
  end

  def project_nested_ul(projects, &block)
    s = ''
    if projects.any?
      ancestors = []
      projects.sort_by(&:lft).each do |project|
        if (ancestors.empty? || project.is_descendant_of?(ancestors.last))
          s << "<ul>\n"
        else
          ancestors.pop
          s << "</li>"
          while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
            ancestors.pop
            s << "</ul></li>\n"
          end
        end
        s << "<li>"
        s << yield(project).to_s
        ancestors << project
      end
      s << ("</li></ul>\n" * ancestors.size)
    end
    s
  end

  def principals_check_box_tags(name, principals)
    s = ''
    principals.sort.each do |principal|
      s << "<label>#{ check_box_tag name, principal.id, false } #{h principal}</label>\n"
    end
    s
  end

  # Truncates and returns the string as a single line
  def truncate_single_line(string, *args)
    truncate(string.to_s, *args).gsub(%r{[\r\n]+}m, ' ')
  end

  # Truncates at line break after 250 characters or options[:length]
  def truncate_lines(string, options={})
    length = options[:length] || 250
    if string.to_s =~ /\A(.{#{length}}.*?)$/m
      "#{$1}..."
    else
      string
    end
  end

  def html_hours(text)
    text.gsub(%r{(\d+)\.(\d+)}, '<span class="hours hours-int">\1</span><span class="hours hours-dec">.\2</span>')
  end

  def authoring(created, author, options={})
    l(options[:label] || :label_added_time_by, :author => link_to_user(author), :age => time_tag(created))
  end

  def time_tag(time)
    text = distance_of_time_in_words(Time.now, time)
    if @project
      link_to(text, {:controller => 'activities', :action => 'index', :id => @project, :from => time.to_date}, :title => format_time(time))
    else
      content_tag('acronym', text, :title => format_time(time))
    end
  end

  def syntax_highlight(name, content)
    Redmine::SyntaxHighlighting.highlight_by_filename(content, name)
  end

  def to_path_param(path)
    path.to_s.split(%r{[/\\]}).select {|p| !p.blank?}
  end

  def pagination_links_full(paginator, count=nil, options={})
    page_param = options.delete(:page_param) || :page
    per_page_links = options.delete(:per_page_links)
    url_param = params.dup
    # don't reuse query params if filters are present
    url_param.merge!(:fields => nil, :values => nil, :operators => nil) if url_param.delete(:set_filter)

    html = ''
    if paginator.current.previous
      html << link_to_content_update('&#171; ' + l(:label_previous), url_param.merge(page_param => paginator.current.previous)) + ' '
    end

    html << (pagination_links_each(paginator, options) do |n|
      link_to_content_update(n.to_s, url_param.merge(page_param => n))
    end || '')

    if paginator.current.next
      html << ' ' + link_to_content_update((l(:label_next) + ' &#187;'), url_param.merge(page_param => paginator.current.next))
    end

    unless count.nil?
      html << " (#{paginator.current.first_item}-#{paginator.current.last_item}/#{count})"
      if per_page_links != false && links = per_page_links(paginator.items_per_page)
	      html << " | #{links}"
      end
    end

    html
  end

  def per_page_links(selected=nil)
    links = Setting.per_page_options_array.collect do |n|
      n == selected ? n : link_to_content_update(n, params.merge(:per_page => n))
    end
    links.size > 1 ? l(:label_display_per_page, links.join(', ')) : nil
  end

  def reorder_links(name, url)
    link_to(image_tag('2uparrow.png',   :alt => l(:label_sort_highest)), url.merge({"#{name}[move_to]" => 'highest'}), :method => :post, :title => l(:label_sort_highest)) +
    link_to(image_tag('1uparrow.png',   :alt => l(:label_sort_higher)),  url.merge({"#{name}[move_to]" => 'higher'}),  :method => :post, :title => l(:label_sort_higher)) +
    link_to(image_tag('1downarrow.png', :alt => l(:label_sort_lower)),   url.merge({"#{name}[move_to]" => 'lower'}),   :method => :post, :title => l(:label_sort_lower)) +
    link_to(image_tag('2downarrow.png', :alt => l(:label_sort_lowest)),  url.merge({"#{name}[move_to]" => 'lowest'}),  :method => :post, :title => l(:label_sort_lowest))
  end

  def breadcrumb(*args)
    elements = args.flatten
    elements.any? ? content_tag('p', args.join(' &#187; ') + ' &#187; ', :class => 'breadcrumb') : nil
  end

  def other_formats_links(&block)
    concat('<p class="other-formats">' + l(:label_export_to))
    yield Redmine::Views::OtherFormatsBuilder.new(self)
    concat('</p>')
  end

  def page_header_title
    if @project.nil? || @project.new_record?
      h(Setting.app_title)
    else
      b = []
      ancestors = (@project.root? ? [] : @project.ancestors.visible)
      if ancestors.any?
        root = ancestors.shift
        b << link_to_project(root, {:jump => current_menu_item}, :class => 'root')
        if ancestors.size > 2
          b << '&#8230;'
          ancestors = ancestors[-2, 2]
        end
        b += ancestors.collect {|p| link_to_project(p, {:jump => current_menu_item}, :class => 'ancestor') }
      end
      b << h(@project)
      b.join(' &#187; ')
    end
  end

  def html_title(*args)
    if args.empty?
      title = []
      title << h(@project.name) if @project
      title += @html_title if @html_title
      title << h(Setting.app_title)
      title.select {|t| !t.blank? }.join(' - ')
    else
      @html_title ||= []
      @html_title += args
    end
  end

  # Returns the theme, controller name, and action as css classes for the
  # HTML body.
  def body_css_classes
    css = []
    if theme = Redmine::Themes.theme(Setting.ui_theme)
      css << 'theme-' + theme.name
    end

    css << 'controller-' + params[:controller]
    css << 'action-' + params[:action]
    css.join(' ')
  end

  def accesskey(s)
    Redmine::AccessKeys.key_for s
  end

  # Formats text according to system settings.
  # 2 ways to call this method:
  # * with a String: textilizable(text, options)
  # * with an object and one of its attribute: textilizable(issue, :description, options)
  def textilizable(*args)
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
      raise ArgumentError, 'invalid arguments to textilizable'
    end
    return '' if text.blank?
    project = options[:project] || @project || (obj && obj.respond_to?(:project) ? obj.project : nil)
    only_path = options.delete(:only_path) == false ? false : true

    text = Redmine::WikiFormatting.to_html(Setting.text_formatting, text, :object => obj, :attribute => attr) { |macro, args| exec_macro(macro, obj, args) }

    @parsed_headings = []
    text = parse_non_pre_blocks(text) do |text|
      [:parse_inline_attachments, :parse_wiki_links, :parse_redmine_links, :parse_headings].each do |method_name|
        send method_name, text, project, obj, attr, only_path, options
      end
    end

    if @parsed_headings.any?
      replace_toc(text, @parsed_headings)
    end

    text
  end

  def parse_non_pre_blocks(text)
    s = StringScanner.new(text)
    tags = []
    parsed = ''
    while !s.eos?
      s.scan(/(.*?)(<(\/)?(pre|code)(.*?)>|\z)/im)
      text, full_tag, closing, tag = s[1], s[2], s[3], s[4]
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

  def parse_inline_attachments(text, project, obj, attr, only_path, options)
    # when using an image link, try to use an attachment, if possible
    if options[:attachments] || (obj && obj.respond_to?(:attachments))
      attachments = nil
      text.gsub!(/src="([^\/"]+\.(bmp|gif|jpg|jpeg|png))"(\s+alt="([^"]*)")?/i) do |m|
        filename, ext, alt, alttext = $1.downcase, $2, $3, $4
        attachments ||= (options[:attachments] || obj.attachments).sort_by(&:created_on).reverse
        # search for the picture in attachments
        if found = attachments.detect { |att| att.filename.downcase == filename }
          image_url = url_for :only_path => only_path, :controller => 'attachments', :action => 'download', :id => found
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
  def parse_wiki_links(text, project, obj, attr, only_path, options)
    text.gsub!(/(!)?(\[\[([^\]\n\|]+)(\|([^\]\n\|]+))?\]\])/) do |m|
      link_project = project
      esc, all, page, title = $1, $2, $3, $5
      if esc.nil?
        if page =~ /^([^\:]+)\:(.*)$/
          link_project = Project.find_by_identifier($1) || Project.find_by_name($1)
          page = $2
          title ||= $1 if page.blank?
        end

        if link_project && link_project.wiki
          # extract anchor
          anchor = nil
          if page =~ /^(.+?)\#(.+)$/
            page, anchor = $1, $2
          end
          # check if page exists
          wiki_page = link_project.wiki.find_page(page)
          url = case options[:wiki_links]
            when :local; "#{title}.html"
            when :anchor; "##{title}"   # used for single-file wiki export
            else
              wiki_page_id = page.present? ? Wiki.titleize(page) : nil
              url_for(:only_path => only_path, :controller => 'wiki', :action => 'show', :project_id => link_project, :id => wiki_page_id, :anchor => anchor)
            end
          link_to(h(title || page), url, :class => ('wiki-page' + (wiki_page ? '' : ' new')))
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
    text.gsub!(%r{([\s\(,\-\[\>]|^)(!)?(([a-z0-9\-]+):)?(attachment|document|version|commit|source|export|message|project)?((#|r)(\d+)|(:)([^"\s<>][^\s<>]*?|"[^"]+?"))(?=(?=[[:punct:]]\W)|,|\s|\]|<|$)}) do |m|
      leading, esc, project_prefix, project_identifier, prefix, sep, identifier = $1, $2, $3, $4, $5, $7 || $9, $8 || $10
      link = nil
      if project_identifier
        project = Project.visible.find_by_identifier(project_identifier)
      end
      if esc.nil?
        if prefix.nil? && sep == 'r'
          # project.changesets.visible raises an SQL error because of a double join on repositories
          if project && project.repository && (changeset = Changeset.visible.find_by_repository_id_and_revision(project.repository.id, identifier))
            link = link_to(h("#{project_prefix}r#{identifier}"), {:only_path => only_path, :controller => 'repositories', :action => 'revision', :id => project, :rev => changeset.revision},
                                      :class => 'changeset',
                                      :title => truncate_single_line(changeset.comments, :length => 100))
          end
        elsif sep == '#'
          oid = identifier.to_i
          case prefix
          when nil
            if issue = Issue.visible.find_by_id(oid, :include => :status)
              link = link_to("##{oid}", {:only_path => only_path, :controller => 'issues', :action => 'show', :id => oid},
                                        :class => issue.css_classes,
                                        :title => "#{truncate(issue.subject, :length => 100)} (#{issue.status.name})")
            end
          when 'document'
            if document = Document.visible.find_by_id(oid)
              link = link_to h(document.title), {:only_path => only_path, :controller => 'documents', :action => 'show', :id => document},
                                                :class => 'document'
            end
          when 'version'
            if version = Version.visible.find_by_id(oid)
              link = link_to h(version.name), {:only_path => only_path, :controller => 'versions', :action => 'show', :id => version},
                                              :class => 'version'
            end
          when 'message'
            if message = Message.visible.find_by_id(oid, :include => :parent)
              link = link_to_message(message, {:only_path => only_path}, :class => 'message')
            end
          when 'project'
            if p = Project.visible.find_by_id(oid)
              link = link_to_project(p, {:only_path => only_path}, :class => 'project')
            end
          end
        elsif sep == ':'
          # removes the double quotes if any
          name = identifier.gsub(%r{^"(.*)"$}, "\\1")
          case prefix
          when 'document'
            if project && document = project.documents.visible.find_by_title(name)
              link = link_to h(document.title), {:only_path => only_path, :controller => 'documents', :action => 'show', :id => document},
                                                :class => 'document'
            end
          when 'version'
            if project && version = project.versions.visible.find_by_name(name)
              link = link_to h(version.name), {:only_path => only_path, :controller => 'versions', :action => 'show', :id => version},
                                              :class => 'version'
            end
          when 'commit'
            if project && project.repository && (changeset = Changeset.visible.find(:first, :conditions => ["repository_id = ? AND scmid LIKE ?", project.repository.id, "#{name}%"]))
              link = link_to h("#{project_prefix}#{name}"), {:only_path => only_path, :controller => 'repositories', :action => 'revision', :id => project, :rev => changeset.identifier},
                                           :class => 'changeset',
                                           :title => truncate_single_line(h(changeset.comments), :length => 100)
            end
          when 'source', 'export'
            if project && project.repository && User.current.allowed_to?(:browse_repository, project)
              name =~ %r{^[/\\]*(.*?)(@([0-9a-f]+))?(#(L\d+))?$}
              path, rev, anchor = $1, $3, $5
              link = link_to h("#{project_prefix}#{prefix}:#{name}"), {:controller => 'repositories', :action => 'entry', :id => project,
                                                      :path => to_path_param(path),
                                                      :rev => rev,
                                                      :anchor => anchor,
                                                      :format => (prefix == 'export' ? 'raw' : nil)},
                                                     :class => (prefix == 'export' ? 'source download' : 'source')
            end
          when 'attachment'
            attachments = options[:attachments] || (obj && obj.respond_to?(:attachments) ? obj.attachments : nil)
            if attachments && attachment = attachments.detect {|a| a.filename == name }
              link = link_to h(attachment.filename), {:only_path => only_path, :controller => 'attachments', :action => 'download', :id => attachment},
                                                     :class => 'attachment'
            end
          when 'project'
            if p = Project.visible.find(:first, :conditions => ["identifier = :s OR LOWER(name) = :s", {:s => name.downcase}])
              link = link_to_project(p, {:only_path => only_path}, :class => 'project')
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
  def parse_headings(text, project, obj, attr, only_path, options)
    return if options[:headings] == false

    text.gsub!(HEADING_RE) do
      level, attrs, content = $1.to_i, $2, $3
      item = strip_tags(content).strip
      anchor = item.gsub(%r{[^\w\s\-]}, '').gsub(%r{\s+(\-+\s*)?}, '-')
      @parsed_headings << [level, anchor, item]
      "<a name=\"#{anchor}\"></a>\n<h#{level} #{attrs}>#{content}<a href=\"##{anchor}\" class=\"wiki-anchor\">&para;</a></h#{level}>"
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
        out = "<ul class=\"#{div_class}\"><li>"
        root = headings.map(&:first).min
        current = root
        started = false
        headings.each do |level, anchor, item|
          if level > current
            out << '<ul><li>' * (level - current)
          elsif level < current
            out << "</li></ul>\n" * (current - level) + "</li><li>"
          elsif started
            out << '</li><li>'
          end
          out << "<a href=\"##{anchor}\">#{item}</a>"
          current = level
          started = true
        end
        out << '</li></ul>' * (current - root)
        out << '</li></ul>'
      end
    end
  end

  # Same as Rails' simple_format helper without using paragraphs
  def simple_format_without_paragraph(text)
    text.to_s.
      gsub(/\r\n?/, "\n").                    # \r\n and \r -> \n
      gsub(/\n\n+/, "<br /><br />").          # 2+ newline  -> 2 br
      gsub(/([^\n]\n)(?=[^\n])/, '\1<br />')  # 1 newline   -> br
  end

  def lang_options_for_select(blank=true)
    (blank ? [["(auto)", ""]] : []) +
      valid_languages.collect{|lang| [ ll(lang.to_s, :general_lang_name), lang.to_s]}.sort{|x,y| x.last <=> y.last }
  end

  def label_tag_for(name, option_tags = nil, options = {})
    label_text = l(("field_"+field.to_s.gsub(/\_id$/, "")).to_sym) + (options.delete(:required) ? @template.content_tag("span", " *", :class => "required"): "")
    content_tag("label", label_text)
  end

  def labelled_tabular_form_for(name, object, options, &proc)
    options[:html] ||= {}
    options[:html][:class] = 'tabular' unless options[:html].has_key?(:class)
    form_for(name, object, options.merge({ :builder => TabularFormBuilder, :lang => current_language}), &proc)
  end

  def back_url_hidden_field_tag
    back_url = params[:back_url] || request.env['HTTP_REFERER']
    back_url = CGI.unescape(back_url.to_s)
    hidden_field_tag('back_url', CGI.escape(back_url)) unless back_url.blank?
  end

  def check_all_links(form_name)
    link_to_function(l(:button_check_all), "checkAll('#{form_name}', true)") +
    " | " +
    link_to_function(l(:button_uncheck_all), "checkAll('#{form_name}', false)")
  end

  def progress_bar(pcts, options={})
    pcts = [pcts, pcts] unless pcts.is_a?(Array)
    pcts = pcts.collect(&:round)
    pcts[1] = pcts[1] - pcts[0]
    pcts << (100 - pcts[1] - pcts[0])
    width = options[:width] || '100px;'
    legend = options[:legend] || ''
    content_tag('table',
      content_tag('tr',
        (pcts[0] > 0 ? content_tag('td', '', :style => "width: #{pcts[0]}%;", :class => 'closed') : '') +
        (pcts[1] > 0 ? content_tag('td', '', :style => "width: #{pcts[1]}%;", :class => 'done') : '') +
        (pcts[2] > 0 ? content_tag('td', '', :style => "width: #{pcts[2]}%;", :class => 'todo') : '')
      ), :class => 'progress', :style => "width: #{width};") +
      content_tag('p', legend, :class => 'pourcent')
  end

  def checked_image(checked=true)
    if checked
      image_tag 'toggle_check.png'
    end
  end

  def context_menu(url)
    unless @context_menu_included
      content_for :header_tags do
        javascript_include_tag('context_menu') +
          stylesheet_link_tag('context_menu')
      end
      if l(:direction) == 'rtl'
        content_for :header_tags do
          stylesheet_link_tag('context_menu_rtl')
        end
      end
      @context_menu_included = true
    end
    javascript_tag "new ContextMenu('#{ url_for(url) }')"
  end

  def context_menu_link(name, url, options={})
    options[:class] ||= ''
    if options.delete(:selected)
      options[:class] << ' icon-checked disabled'
      options[:disabled] = true
    end
    if options.delete(:disabled)
      options.delete(:method)
      options.delete(:confirm)
      options.delete(:onclick)
      options[:class] << ' disabled'
      url = '#'
    end
    link_to h(name), url, options
  end

  def calendar_for(field_id)
    include_calendar_headers_tags
    image_tag("calendar.png", {:id => "#{field_id}_trigger",:class => "calendar-trigger"}) +
    javascript_tag("Calendar.setup({inputField : '#{field_id}', ifFormat : '%Y-%m-%d', button : '#{field_id}_trigger' });")
  end

  def include_calendar_headers_tags
    unless @calendar_headers_tags_included
      @calendar_headers_tags_included = true
      content_for :header_tags do
        start_of_week = case Setting.start_of_week.to_i
        when 1
          'Calendar._FD = 1;' # Monday
        when 7
          'Calendar._FD = 0;' # Sunday
        when 6
          'Calendar._FD = 6;' # Saturday
        else
          '' # use language
        end

        javascript_include_tag('calendar/calendar') +
        javascript_include_tag("calendar/lang/calendar-#{current_language.to_s.downcase}.js") +
        javascript_tag(start_of_week) +
        javascript_include_tag('calendar/calendar-setup') +
        stylesheet_link_tag('calendar')
      end
    end
  end

  def content_for(name, content = nil, &block)
    @has_content ||= {}
    @has_content[name] = true
    super(name, content, &block)
  end

  def has_content?(name)
    (@has_content && @has_content[name]) || false
  end

  # Returns the avatar image tag for the given +user+ if avatars are enabled
  # +user+ can be a User or a string that will be scanned for an email address (eg. 'joe <joe@foo.bar>')
  def avatar(user, options = { })
    if Setting.gravatar_enabled?
      options.merge!({:ssl => (defined?(request) && request.ssl?), :default => Setting.gravatar_default})
      email = nil
      if user.respond_to?(:mail)
        email = user.mail
      elsif user.to_s =~ %r{<(.+?)>}
        email = $1
      end
      return gravatar(email.to_s.downcase, options) unless email.blank? rescue nil
    else
      ''
    end
  end

  # Returns the javascript tags that are included in the html layout head
  def javascript_heads
    tags = javascript_include_tag(:defaults)
    unless User.current.pref.warn_on_leaving_unsaved == '0'
      tags << "\n" + javascript_tag("Event.observe(window, 'load', function(){ new WarnLeavingUnsaved('#{escape_javascript( l(:text_warn_on_leaving_unsaved) )}'); });")
    end
    tags
  end

  def favicon
    "<link rel='shortcut icon' href='#{image_path('/favicon.ico')}' />"
  end

  # Add a HTML meta tag to control robots (web spiders)
  #
  # @param [optional, String] content the content of the ROBOTS tag.
  #   defaults to no index, follow, and no archive
  def robot_exclusion_tag(content="NOINDEX,FOLLOW,NOARCHIVE")
    "<meta name='ROBOTS' content='#{h(content)}' />"
  end

  # Returns true if arg is expected in the API response
  def include_in_api_response?(arg)
    unless @included_in_api_response
      param = params[:include]
      @included_in_api_response = param.is_a?(Array) ? param.collect(&:to_s) : param.to_s.split(',')
      @included_in_api_response.collect!(&:strip)
    end
    @included_in_api_response.include?(arg.to_s)
  end

  # Returns options or nil if nometa param or X-ChiliProject-Nometa header
  # was set in the request
  def api_meta(options)
    if params[:nometa].present? || request.headers['X-ChiliProject-Nometa']
      # compatibility mode for activeresource clients that raise
      # an error when unserializing an array with attributes
      nil
    else
      options
    end
  end

  private

  def wiki_helper
    helper = Redmine::WikiFormatting.helper_for(Setting.text_formatting)
    extend helper
    return self
  end

  def link_to_content_update(text, url_params = {}, html_options = {})
    link_to(text, url_params, html_options)
  end
end
