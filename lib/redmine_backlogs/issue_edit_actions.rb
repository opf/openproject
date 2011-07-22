class RedmineBacklogs::IssueEditActions < ChiliProject::Nissue::View
  attr_reader :html_id

  def initialize(issue, html_id, form_id)
    @issue = issue
    @html_id = html_id
    @form_id = form_id
  end

  def render(t)
    css_class = "watcher_link_#{@issue.id}"
    content_tag(:div, [
        t.link_to_issue_box(l(:button_cancel), @issue, :class => 'icon icon-cancel'),
        (t.link_to_remote(l(:button_save), 
                           { :url => { :controller => 'issue_boxes', :action => 'update', :id => @issue },
                             :method => 'PUT',
                             :update => @html_id,
                             :with => "Form.serialize('#{@form_id}')"
                           }, { :class => 'icon icon-save', :accesskey => t.accesskey(:update) }) if t.authorize_for('issue_boxes', 'update'))
      ], :class => 'contextual')
  end
end
