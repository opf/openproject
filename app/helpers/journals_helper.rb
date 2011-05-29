module JournalsHelper
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

  def render_journal(model, journal, options = {})
    return "" if journal.initial?
    journal_content = render_journal_details(journal, :label_updated_time_by)
    journal_content += render_notes(model, journal, options) unless journal.notes.blank?
    content_tag "div", journal_content, { :id => "change-#{journal.id}", :class => journal.css_classes }
  end

  # This renders a journal entry wiht a header and details
  def render_journal_details(journal, header_label = :label_updated_time_by)
    header = <<-HTML
      <h4>
        <div style="float:right;">#{link_to "##{journal.anchor}", :anchor => "note-#{journal.anchor}"}</div>
        #{avatar(journal.user, :size => "24")}
        #{content_tag('a', '', :name => "note-#{journal.anchor}")}
        #{authoring journal.created_at, journal.user, :label => header_label}
      </h4>
    HTML

    if journal.details.any?
      details = content_tag "ul", :class => "details" do
        journal.details.collect do |detail|
          if d = journal.render_detail(detail)
            content_tag("li", d)
          end
        end.compact
      end
    end

    content_tag("div", "#{header}#{details}", :id => "change-#{journal.id}", :class => "journal")
  end

  def render_notes(model, journal, options={})
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
          l << link_to_remote(image_tag('comment.png'), :title => l(:button_quote),
            :url => {:controller => controller, :action => action, :id => model, :journal_id => journal})
        end
        if editable
          l << link_to_in_place_notes_editor(image_tag('edit.png'), "journal-#{journal.id}-notes",
                { :controller => 'journals', :action => 'edit', :id => journal },
                  :title => l(:button_edit))
        end
      end
    end

    content = ''
    content << content_tag('div', links.join(' '), :class => 'contextual') unless links.empty?
    content << textilizable(journal, :notes)

    css_classes = "wiki"
    css_classes << " editable" if editable

    content_tag('div', content, :id => "journal-#{journal.id}-notes", :class => css_classes)
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
