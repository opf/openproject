# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

module ApplicationHelper
  include Redmine::WikiFormatting::Macros::Definitions

  def current_role
    @current_role ||= User.current.role_for_project(@project)
  end
  
  # Return true if user is authorized for controller/action, otherwise false
  def authorize_for(controller, action)
    User.current.allowed_to?({:controller => controller, :action => action}, @project)
  end

  # Display a link if user is authorized
  def link_to_if_authorized(name, options = {}, html_options = nil, *parameters_for_method_reference)
    link_to(name, options, html_options, *parameters_for_method_reference) if authorize_for(options[:controller] || params[:controller], options[:action])
  end
  
  def link_to_signin
    link_to l(:label_login), { :controller => 'account', :action => 'login' }, :class => 'signin'
  end
  
  def link_to_signout
    link_to l(:label_logout), { :controller => 'account', :action => 'logout' }, :class => 'logout'
  end

  # Display a link to user's account page
  def link_to_user(user)
    user ? link_to(user, :controller => 'account', :action => 'show', :id => user) : 'Anonymous'
  end
  
  def link_to_issue(issue)
    link_to "#{issue.tracker.name} ##{issue.id}", :controller => "issues", :action => "show", :id => issue
  end
  
  def toggle_link(name, id, options={})
    onclick = "Element.toggle('#{id}'); "
    onclick << (options[:focus] ? "Form.Element.focus('#{options[:focus]}'); " : "this.blur(); ")
    onclick << "return false;"
    link_to(name, "#", :onclick => onclick)
  end
  
  def show_and_goto_link(name, id, options={})
    onclick = "Element.show('#{id}'); "
    onclick << (options[:focus] ? "Form.Element.focus('#{options[:focus]}'); " : "this.blur(); ")
    onclick << "location.href='##{id}-anchor'; "
    onclick << "return false;"
    link_to(name, "#", options.merge(:onclick => onclick))
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
  
  def format_date(date)
    return nil unless date
    # "Setting.date_format.size < 2" is a temporary fix (content of date_format setting changed)
    @date_format ||= (Setting.date_format.blank? || Setting.date_format.size < 2 ? l(:general_fmt_date) : Setting.date_format)
    date.strftime(@date_format)
  end
  
  def format_time(time, include_date = true)
    return nil unless time
    time = time.to_time if time.is_a?(String)
    zone = User.current.time_zone
    if time.utc?
      local = zone ? zone.adjust(time) : time.getlocal
    else
      local = zone ? zone.adjust(time.getutc) : time
    end
    @date_format ||= (Setting.date_format.blank? || Setting.date_format.size < 2 ? l(:general_fmt_date) : Setting.date_format)
    @time_format ||= (Setting.time_format.blank? ? l(:general_fmt_time) : Setting.time_format)
    include_date ? local.strftime("#{@date_format} #{@time_format}") : local.strftime(@time_format)
  end
  
  def authoring(created, author)
    time_tag = content_tag('acronym', distance_of_time_in_words(Time.now, created), :title => format_time(created))
    l(:label_added_time_by, author || 'Anonymous', time_tag)
  end
  
  def day_name(day)
    l(:general_day_names).split(',')[day-1]
  end
  
  def month_name(month)
    l(:actionview_datehelper_select_month_names).split(',')[month-1]
  end

  def pagination_links_full(paginator, count=nil, options={})
    page_param = options.delete(:page_param) || :page
    url_param = params.dup
    
    html = ''    
    html << link_to_remote(('&#171; ' + l(:label_previous)), 
                            {:update => "content", :url => url_param.merge(page_param => paginator.current.previous)},
                            {:href => url_for(:params => url_param.merge(page_param => paginator.current.previous))}) + ' ' if paginator.current.previous
                            
    html << (pagination_links_each(paginator, options) do |n|
      link_to_remote(n.to_s, 
                      {:url => {:params => url_param.merge(page_param => n)}, :update => 'content'},
                      {:href => url_for(:params => url_param.merge(page_param => n))})
    end || '')
    
    html << ' ' + link_to_remote((l(:label_next) + ' &#187;'), 
                                 {:update => "content", :url => url_param.merge(page_param => paginator.current.next)},
                                 {:href => url_for(:params => url_param.merge(page_param => paginator.current.next))}) if paginator.current.next
    
    unless count.nil?
      html << [" (#{paginator.current.first_item}-#{paginator.current.last_item}/#{count})", per_page_links(paginator.items_per_page)].compact.join(' | ')
    end
    
    html  
  end
  
  def per_page_links(selected=nil)
    links = Setting.per_page_options_array.collect do |n|
      n == selected ? n : link_to_remote(n, {:update => "content", :url => params.dup.merge(:per_page => n)}, 
                                            {:href => url_for(params.dup.merge(:per_page => n))})
    end
    links.size > 1 ? l(:label_display_per_page, links.join(', ')) : nil
  end
  
  def set_html_title(text)
    @html_header_title = text
  end
  
  def html_title
    title = []
    title << @project.name if @project
    title << @html_header_title
    title << Setting.app_title
    title.compact.join(' - ')
  end
  
  ACCESSKEYS = {:edit => 'e',
                :preview => 'r',
                :quick_search => 'f',
                :search => '4',
                }.freeze unless const_defined?(:ACCESSKEYS)

  def accesskey(s)
    ACCESSKEYS[s]
  end

  # Formats text according to system settings.
  # 2 ways to call this method:
  # * with a String: textilizable(text, options)
  # * with an object and one of its attribute: textilizable(issue, :description, options)
  def textilizable(*args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    case args.size
    when 1
      obj = nil
      text = args.shift || ''
    when 2
      obj = args.shift
      text = obj.send(args.shift)
    else
      raise ArgumentError, 'invalid arguments to textilizable'
    end

    # when using an image link, try to use an attachment, if possible
    attachments = options[:attachments]
    if attachments
      text = text.gsub(/!((\<|\=|\>)?(\([^\)]+\))?(\[[^\]]+\])?(\{[^\}]+\})?)(\S+\.(gif|jpg|jpeg|png))!/) do |m|
        style = $1
        filename = $6
        rf = Regexp.new(filename,  Regexp::IGNORECASE)
        # search for the picture in attachments
        if found = attachments.detect { |att| att.filename =~ rf }
          image_url = url_for :controller => 'attachments', :action => 'download', :id => found.id
          "!#{style}#{image_url}!"
        else
          "!#{style}#{filename}!"
        end
      end
    end
    
    text = (Setting.text_formatting == 'textile') ?
      Redmine::WikiFormatting.to_html(text) { |macro, args| exec_macro(macro, obj, args) } :
      simple_format(auto_link(h(text)))

    # different methods for formatting wiki links
    case options[:wiki_links]
    when :local
      # used for local links to html files
      format_wiki_link = Proc.new {|project, title| "#{title}.html" }
    when :anchor
      # used for single-file wiki export
      format_wiki_link = Proc.new {|project, title| "##{title}" }
    else
      format_wiki_link = Proc.new {|project, title| url_for :controller => 'wiki', :action => 'index', :id => project, :page => title }
    end
    
    project = options[:project] || @project
    
    # turn wiki links into html links
    # example:
    #   [[mypage]]
    #   [[mypage|mytext]]
    # wiki links can refer other project wikis, using project name or identifier:
    #   [[project:]] -> wiki starting page
    #   [[project:|mytext]]
    #   [[project:mypage]]
    #   [[project:mypage|mytext]]
    text = text.gsub(/\[\[([^\]\|]+)(\|([^\]\|]+))?\]\]/) do |m|
      link_project = project
      page = $1
      title = $3
      if page =~ /^([^\:]+)\:(.*)$/
        link_project = Project.find_by_name($1) || Project.find_by_identifier($1)
        page = title || $2
        title = $1 if page.blank?
      end
      
      if link_project && link_project.wiki
        # check if page exists
        wiki_page = link_project.wiki.find_page(page)
        link_to((title || page), format_wiki_link.call(link_project, Wiki.titleize(page)),
                                 :class => ('wiki-page' + (wiki_page ? '' : ' new')))
      else
        # project or wiki doesn't exist
        title || page
      end
    end

    # turn issue and revision ids into links
    # example:
    #   #52 -> <a href="/issues/show/52">#52</a>
    #   r52 -> <a href="/repositories/revision/6?rev=52">r52</a> (project.id is 6)
    text = text.gsub(%r{([\s\(,-^])(#|r)(\d+)(?=[[:punct:]]|\s|<|$)}) do |m|
      leading, otype, oid = $1, $2, $3
      link = nil
      if otype == 'r'
        if project && (changeset = project.changesets.find_by_revision(oid))
          link = link_to("r#{oid}", {:controller => 'repositories', :action => 'revision', :id => project.id, :rev => oid}, :class => 'changeset',
                                    :title => truncate(changeset.comments, 100))
        end
      else
        if issue = Issue.find_by_id(oid.to_i, :include => [:project, :status], :conditions => Project.visible_by(User.current))        
          link = link_to("##{oid}", {:controller => 'issues', :action => 'show', :id => oid}, :class => 'issue',
                                    :title => "#{truncate(issue.subject, 100)} (#{issue.status.name})")
          link = content_tag('del', link) if issue.closed?
        end
      end
      leading + (link || "#{otype}#{oid}")
    end
    
    text
  end
  
  # Same as Rails' simple_format helper without using paragraphs
  def simple_format_without_paragraph(text)
    text.to_s.
      gsub(/\r\n?/, "\n").                    # \r\n and \r -> \n
      gsub(/\n\n+/, "<br /><br />").          # 2+ newline  -> 2 br
      gsub(/([^\n]\n)(?=[^\n])/, '\1<br />')  # 1 newline   -> br
  end
  
  def error_messages_for(object_name, options = {})
    options = options.symbolize_keys
    object = instance_variable_get("@#{object_name}")
    if object && !object.errors.empty?
      # build full_messages here with controller current language
      full_messages = []
      object.errors.each do |attr, msg|
        next if msg.nil?
        msg = msg.first if msg.is_a? Array
        if attr == "base"
          full_messages << l(msg)
        else
          full_messages << "&#171; " + (l_has_string?("field_" + attr) ? l("field_" + attr) : object.class.human_attribute_name(attr)) + " &#187; " + l(msg) unless attr == "custom_values"
        end
      end
      # retrieve custom values error messages
      if object.errors[:custom_values]
        object.custom_values.each do |v| 
          v.errors.each do |attr, msg|
            next if msg.nil?
            msg = msg.first if msg.is_a? Array
            full_messages << "&#171; " + v.custom_field.name + " &#187; " + l(msg)
          end
        end
      end      
      content_tag("div",
        content_tag(
          options[:header_tag] || "span", lwr(:gui_validation_error, full_messages.length) + ":"
        ) +
        content_tag("ul", full_messages.collect { |msg| content_tag("li", msg) }),
        "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
      )
    else
      ""
    end
  end
  
  def lang_options_for_select(blank=true)
    (blank ? [["(auto)", ""]] : []) + 
      GLoc.valid_languages.collect{|lang| [ ll(lang.to_s, :general_lang_name), lang.to_s]}.sort{|x,y| x.last <=> y.last }
  end
  
  def label_tag_for(name, option_tags = nil, options = {})
    label_text = l(("field_"+field.to_s.gsub(/\_id$/, "")).to_sym) + (options.delete(:required) ? @template.content_tag("span", " *", :class => "required"): "")
    content_tag("label", label_text)
  end
  
  def labelled_tabular_form_for(name, object, options, &proc)
    options[:html] ||= {}
    options[:html].store :class, "tabular"
    form_for(name, object, options.merge({ :builder => TabularFormBuilder, :lang => current_language}), &proc)
  end
  
  def check_all_links(form_name)
    link_to_function(l(:button_check_all), "checkAll('#{form_name}', true)") +
    " | " +
    link_to_function(l(:button_uncheck_all), "checkAll('#{form_name}', false)")   
  end
  
  def progress_bar(pcts, options={})
    pcts = [pcts, pcts] unless pcts.is_a?(Array)
    pcts[1] = pcts[1] - pcts[0]
    pcts << (100 - pcts[1] - pcts[0])
    width = options[:width] || '100px;'
    legend = options[:legend] || ''
    content_tag('table',
      content_tag('tr',
        (pcts[0] > 0 ? content_tag('td', '', :width => "#{pcts[0].floor}%;", :class => 'closed') : '') +
        (pcts[1] > 0 ? content_tag('td', '', :width => "#{pcts[1].floor}%;", :class => 'done') : '') +
        (pcts[2] > 0 ? content_tag('td', '', :width => "#{pcts[2].floor}%;", :class => 'todo') : '')
      ), :class => 'progress', :style => "width: #{width};") +
      content_tag('p', legend, :class => 'pourcent')
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
    link_to name, url, options
  end
  
  def calendar_for(field_id)
    image_tag("calendar.png", {:id => "#{field_id}_trigger",:class => "calendar-trigger"}) +
    javascript_tag("Calendar.setup({inputField : '#{field_id}', ifFormat : '%Y-%m-%d', button : '#{field_id}_trigger' });")
  end
  
  def wikitoolbar_for(field_id)
    return '' unless Setting.text_formatting == 'textile'
    javascript_include_tag('jstoolbar') + javascript_tag("var toolbar = new jsToolBar($('#{field_id}')); toolbar.draw();")
  end
  
  def content_for(name, content = nil, &block)
    @has_content ||= {}
    @has_content[name] = true
    super(name, content, &block)
  end
  
  def has_content?(name)
    (@has_content && @has_content[name]) || false
  end
end
