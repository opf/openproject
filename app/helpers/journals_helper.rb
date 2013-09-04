#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module JournalsHelper
  # unloadable
  include ApplicationHelper
  include ERB::Util
  include ActionView::Helpers::TagHelper

  def self.included(base)
    base.class_eval do
      if respond_to? :before_filter
        before_filter :find_optional_journal, :only => [:edit]
      end
    end
  end

  def render_journal(model, journal, options = {})
    return "" if journal.initial?
    journal_content = render_journal_details(journal, :label_updated_time_by, model, options)
    content_tag "div", journal_content, { :id => "change-#{journal.id}", :class => work_package_css_classes(journal.journable) }
  end

  # This renders a journal entry with a header and details
  def render_journal_details(journal, header_label = :label_updated_time_by, model=nil, options={})
    header = <<-HTML
      <div class="profile-wrap">
        #{avatar(journal.user, :size => "40")}
      </div>
      <h4>
        <div class="journal-link" style="float:right;">#{link_to "##{journal.anchor}", :anchor => "note-#{journal.anchor}"}</div>
        #{authoring journal.created_at, journal.user, :label => header_label}
        #{content_tag('a', '', :name => "note-#{journal.anchor}")}
      </h4>
    HTML

    if journal.details.any?
      details = content_tag "ul", :class => "details journal-attributes" do
        journal.details.collect do |detail|
          if d = journal.render_detail(detail, :cache => options[:cache])
            content_tag("li", d.html_safe)
          end
        end.compact.join(' ').html_safe
      end
    end

    notes = journal.notes.blank? ?
              '' :
              render_notes(model, journal, options)

    content_tag("div", "#{header}#{details}#{notes}".html_safe, :id => "change-#{journal.id}", :class => "journal")
  end

  def render_notes(model, journal, options={})
    controller = "/#{model.class.name.downcase.pluralize}"
    action = 'edit'
    reply_links = authorize_for(controller, action)

    if User.current.logged?
      editable = User.current.allowed_to?(options[:edit_permission], journal.project) if options[:edit_permission]
      if journal.user == User.current && options[:edit_own_permission]
        editable ||= User.current.allowed_to?(options[:edit_own_permission], journal.project)
      end
    end

    unless journal.notes.blank?
      links = [].tap do |l|
        if reply_links
          l << link_to(image_tag('quote.png', :alt => l(:button_quote), :title => l(:button_quote)),
                                                { :controller => controller,
                                                  :action => 'quoted',
                                                  :id => model,
                                                  :journal_id => journal }, :class => 'quote-link')
        end
        if editable
          l << link_to_in_place_notes_editor(image_tag('edit.png', :alt => l(:button_edit), :title => l(:button_edit)), "journal-#{journal.id}-notes",
                { :controller => '/journals', :action => 'edit', :id => journal },
                  :title => l(:button_edit))
        end
      end
    end

    content = ''
    content << content_tag('div', links.join(' '),{ :class => 'contextual' }, false) unless links.empty?
    content << content_tag('div', textilizable(journal, :notes), :class => 'wikicontent', "data-user" => journal.journable.author)

    css_classes = "wiki"
    css_classes << " editable" if editable

    content_tag('div', content, { :id => "journal-#{journal.id}-notes", :class => css_classes }, false)
  end

  def link_to_in_place_notes_editor(text, field_id, url, options={})
    onclick = "new Ajax.Request('#{url_for(url)}', {asynchronous:true, evalScripts:true, method:'get'}); return false;"
    link_to text, '#', options.merge(:onclick => onclick)
  end

  # This may conveniently be used by controllers to find journals referred to in the current request
  def find_optional_journal
    @journal = Journal.find_by_id(params[:journal_id])
  end

  def render_reply(journal)
    user = journal.user
    text = journal.notes

    # Replaces pre blocks with [...]
    text = text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]')
    content = "#{ll(Setting.default_language, :text_user_wrote, user)}\n> "
    content << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"

    render(:update) do |page|
      page << "$('notes').value = \"#{escape_javascript content}\";"
      page.show 'update'
      page << "Form.Element.focus('notes');"
      page << "Element.scrollTo('update');"
      page << "$('notes').scrollTop = $('notes').scrollHeight - $('notes').clientHeight;"
    end
  end
end
