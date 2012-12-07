require_dependency 'journal_formatter/base'

class OpenProject::JournalFormatter::Diff < JournalFormatter::Base
  unloadable

  def render(key, values, no_html = false)
    label = label(key)

    render_ternary_detail_text(label, values.last, values.first, no_html)
  end

  private

  def format_html_detail(label)
    content_tag('strong', label)
  end

  def render_ternary_detail_text(label, value, old_value, no_html)
    link = link(label, no_html)

    label = format_html_detail(label) unless no_html

    if value.blank?
      l(:text_journal_deleted_with_diff, :label => label, :link => link)
    else
      unless old_value.blank?
        l(:text_journal_changed_with_diff, :label => label, :link => link)
      else
        l(:text_journal_set_with_diff, :label => label, :link => link)
      end
    end
  end

  def link(label, no_html)
    url_attr = { :controller => 'journals',
                 :action => 'diff',
                 :id => @journal.id,
                 :field => label.downcase,
                 :only_path => false,
                 :protocol => Setting.protocol,
                 :host => Setting.host_name }

    if no_html
      url_for url_attr
    else
      link_to(l(:label_details),
                url_attr,
                :class => 'description-details')
    end
  end
end

