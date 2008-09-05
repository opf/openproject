<div class="contextual">
<%= link_to_if_authorized l(:button_edit), {:controller => 'versions', :action => 'edit', :id => @version}, :class => 'icon icon-edit' %>
</div>

<h2><%= h(@version.name) %></h2>

<div id="version-summary">
<% if @version.estimated_hours > 0 || User.current.allowed_to?(:view_time_entries, @project) %>
<fieldset><legend><%= l(:label_time_tracking) %></legend>
<table>
<tr>
    <td width="130px" align="right"><%= l(:field_estimated_hours) %></td>
    <td width="240px" class="total-hours"width="130px" align="right"><%= html_hours(lwr(:label_f_hour, @version.estimated_hours)) %></td>
</tr>
<% if User.current.allowed_to?(:view_time_entries, @project) %>
<tr>
    <td width="130px" align="right"><%= l(:label_spent_time) %></td>
    <td width="240px" class="total-hours"><%= html_hours(lwr(:label_f_hour, @version.spent_hours)) %></td>
</tr>
<% end %>
</table>
</fieldset>
<% end %>

<div id="status_by">
<%= render_issue_status_by(@version, params[:status_by]) if @version.fixed_issues.count > 0 %>
</div>
</div>

<div id="roadmap">
<%= render :partial => 'versions/overview', :locals => {:version => @version} %>
<%= render(:partial => "wiki/content", :locals => {:content => @version.wiki_page.content}) if @version.wiki_page %>

<% issues = @version.fixed_issues.find(:all,
                                       :include => [:status, :tracker],
                                       :order => "#{Tracker.table_name}.position, #{Issue.table_name}.id") %>
<% if issues.size > 0 %>
<fieldset class="related-issues"><legend><%= l(:label_related_issues) %></legend>
<ul>
<% issues.each do |issue| -%>
    <li><%= link_to_issue(issue) %>: <%=h issue.subject %></li>
<% end -%>
</ul>
</fieldset>
<% end %>
</div>

<%= call_hook :view_versions_show_bottom, :version => @version %>

<% html_title @version.name %>
