#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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

module TimelinesJournalsHelper
  unloadable
  include ApplicationHelper
  include ActionView::Helpers::TagHelper

  def self.included(base)
    base.class_eval do
      if respond_to? :before_filter
        before_filter :find_optional_journal, :only => [:edit]
      end
    end
  end

  def timelines_render_journal(model, journal, options = {})
    return "" if journal.initial?
    journal_content = timelines_render_journal_details(journal, :label_updated_time_at, model, options)
    content_tag("div", journal_content, { :id => "change-#{journal.id}", :class => journal.css_classes }).html_safe
  end

  def timelines_time_tag(time)
    text = format_time(time)
    if @project and @project.module_enabled?("activity")
      link_to(text, {:controller => '/activities', :action => 'index', :project_id => @project, :from => time.to_date}, :title => format_time(time))
    else
      content_tag('label', text, :title => format_time(time), :class => "timestamp")
    end
  end

  # This renders a journal entry with a header and details
  def timelines_render_journal_details(journal, header_label = :label_updated_time_at, model=nil, options={})
    header = <<-HTML
      <div class="profile-wrap">
        #{avatar(journal.user, :size => "40")}
      </div>
      <h4>
        <span>#{link_to "##{journal.anchor}", :anchor => "note-#{journal.anchor}"}</span>

        #{l(header_label, :author => link_to_user(journal.user), :age => timelines_time_tag(journal.created_at))}
        #{content_tag('a', '', :name => "note-#{journal.anchor}")}
      </h4>
    HTML

    if journal.details.any?
      details = content_tag "ul", :class => "details journal-attributes" do
        journal.details.collect do |detail|
          if d = journal.render_detail(detail).html_safe
            content_tag("li", d)
          end
        end.compact.join(' ').html_safe
      end
    end

    notes = <<-HTML
      #{timelines_render_notes(model, journal, options) unless journal.notes.blank?}
    HTML
    content_tag("div", "#{header}#{details}#{notes}".html_safe, :id => "change-#{journal.id}", :class => "journal")
  end

  def timelines_render_notes(model, journal, options={})
    controller = model.class.name.downcase.pluralize
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
          l << link_to_remote(image_tag('webalys/quote.png', :alt => l(:button_quote), :title => l(:button_quote)),
            :url => {:controller => controller, :action => action, :id => model, :journal_id => journal})
        end
        if editable
          l << link_to_in_place_notes_editor(image_tag('webalys/edit.png', :alt => l(:button_edit), :title => l(:button_edit)), "journal-#{journal.id}-notes",
                { :controller => '/journals', :action => 'edit', :id => journal },
                  :title => l(:button_edit))
        end
      end
    end

    content = ''
    content << content_tag('div', links.join(' '), :class => 'contextual') unless links.empty?
    content << textilizable(journal, :notes)

    css_classes = "wiki"
    css_classes << " editable" if editable

    content_tag('div', content.html_safe, :id => "journal-#{journal.id}-notes", :class => css_classes)
  end

end
