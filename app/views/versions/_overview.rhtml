<% if version.completed? %>
  <p><%= format_date(version.effective_date) %></p>
<% elsif version.effective_date %>
  <p><strong><%= due_date_distance_in_words(version.effective_date) %></strong> (<%= format_date(version.effective_date) %>)</p>
<% end %>

<p><%=h version.description %></p>

<% if version.fixed_issues.count > 0 %>
    <%= progress_bar([version.closed_pourcent, version.completed_pourcent], :width => '40em', :legend => ('%0.0f%' % version.completed_pourcent)) %>
    <p class="progress-info">
        <%= link_to(version.closed_issues_count, :controller => 'issues', :action => 'index', :project_id => version.project, :status_id => 'c', :fixed_version_id => version, :set_filter => 1) %>
        <%= lwr(:label_closed_issues, version.closed_issues_count) %>
        (<%= '%0.0f' % (version.closed_issues_count.to_f / version.fixed_issues.count * 100) %>%)
        &#160;
        <%= link_to(version.open_issues_count, :controller => 'issues', :action => 'index', :project_id => version.project, :status_id => 'o', :fixed_version_id => version, :set_filter => 1) %>
        <%= lwr(:label_open_issues, version.open_issues_count)%>
        (<%= '%0.0f' % (version.open_issues_count.to_f / version.fixed_issues.count * 100) %>%)
    </p>
<% else %>
    <p><em><%= l(:label_roadmap_no_issues) %></em></p>
<% end %>
