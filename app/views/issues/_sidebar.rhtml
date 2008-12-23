<h3><%= l(:label_issue_plural) %></h3>
<%= link_to l(:label_issue_view_all), { :controller => 'issues', :action => 'index', :project_id => @project, :set_filter => 1 } %><br />
<% if @project %>
<%= link_to l(:field_summary), :controller => 'reports', :action => 'issue_report', :id => @project %><br />
<%= link_to l(:label_change_log), :controller => 'projects', :action => 'changelog', :id => @project %><br />
<% end %>
<%= call_hook(:view_issues_sidebar_issues_bottom) %>

<% planning_links = []
  planning_links << link_to(l(:label_calendar), :action => 'calendar', :project_id => @project) if User.current.allowed_to?(:view_calendar, @project, :global => true)
  planning_links << link_to(l(:label_gantt), :action => 'gantt', :project_id => @project) if User.current.allowed_to?(:view_gantt, @project, :global => true)
%>
<% unless planning_links.empty? %>
<h3><%= l(:label_planning) %></h3>
<p><%= planning_links.join(' | ') %></p>
<%= call_hook(:view_issues_sidebar_planning_bottom) %>
<% end %>

<% unless sidebar_queries.empty? -%>
<h3><%= l(:label_query_plural) %></h3>

<% sidebar_queries.each do |query| -%>
<%= link_to(h(query.name), :controller => 'issues', :action => 'index', :project_id => @project, :query_id => query) %><br />
<% end -%>
<%= call_hook(:view_issues_sidebar_queries_bottom) %>
<% end -%>
