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

module JournalsHelper
  # unloadable
  include ApplicationHelper
  include ERB::Util
  include ActionView::Helpers::TagHelper

  def self.included(base)
    base.class_eval do
      if respond_to? :before_filter
        before_filter :find_optional_journal, only: [:edit]
      end
    end
  end

  def render_journal(model, journal, options = {})
    return '' if journal.initial?
    journal_content = render_journal_details(journal, :label_updated_time_by, model, options)
    content_tag 'div', journal_content,  id: "change-#{journal.id}", class: work_package_css_classes(journal.journable)
  end

  # This renders a journal entry with a header and details
  def render_journal_details(journal, header_label = :label_updated_time_by, model = nil, options = {})
    header = <<-HTML
      <div class="profile-wrap">
        #{avatar(journal.user)}
      </div>
      <h4>
        <div class="journal-link" style="float:right;">#{link_to "##{journal.anchor}", anchor: "note-#{journal.anchor}"}</div>
        #{authoring journal.created_at, journal.user, label: header_label}
        #{content_tag('a', '', name: "note-#{journal.anchor}")}
      </h4>
    HTML

    if journal.details.any?
      details = content_tag 'ul', class: 'details journal-attributes' do
        journal.details.map do |detail|
          if d = journal.render_detail(detail, cache: options[:cache])
            content_tag('li', d.html_safe)
          end
        end.compact.join(' ').html_safe
      end
    end

    notes = journal.notes.blank? ?
              '' :
              render_notes(model, journal, options)

    content_tag('div', "#{header}#{details}#{notes}".html_safe, id: "change-#{journal.id}", class: 'journal')
  end

  def render_notes(model, journal, options = {})
    editable = journal.editable_by?(User.current) if User.current.logged?

    unless journal.notes.blank?

      links = [].tap do |l|
        if options[:quote_permission] && User.current.allowed_to?(options[:quote_permission], journal.project)
          # TODO: This is a hack.
          # it assumes that there is a quoted action on the controller
          # currently rendering the view
          # the quote link should somehow be supplied
          controller_name = controller.class.to_s.underscore.gsub(/_controller\z/, '').to_sym
          l << link_to(icon_wrapper('icon-context icon-quote', l(:button_quote)),
                       { controller: controller_name,
                         action: 'quoted',
                         id: model,
                         journal_id: journal },
                       title: l(:button_quote),
                       class: 'quote-link no-decoration-on-hover')
        end
        if editable
          l << link_to_in_place_notes_editor(icon_wrapper('icon-context icon-edit', l(:button_edit)), "journal-#{journal.id}-notes",
                                             { controller: '/journals', action: 'edit', id: journal },
                                             class: 'no-decoration-on-hover',
                                             title: l(:button_edit))
        end
      end
    end

    content = ''
    content << content_tag('div', links.join(' '), { class: 'contextual' }, false) unless links.empty?
    attachments = model.try(:attachments) || []
    content << content_tag('div',
                           format_text(journal, :notes, attachments: attachments),
                           class: 'wikicontent',
                           :'ng-non-bindable' => '',
                           'data-user' => journal.journable.author)

    css_classes = 'wiki journal-notes'
    css_classes << ' editable' if editable

    content_tag('div', content, { id: "journal-#{journal.id}-notes", class: css_classes }, false)
  end

  def link_to_in_place_notes_editor(text, _field_id, url, options = {})
    onclick = "new Ajax.Request('#{url_for(url)}', {asynchronous:true, evalScripts:true, method:'get'}); return false;"
    link_to text, '#', options.merge(onclick: onclick)
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
