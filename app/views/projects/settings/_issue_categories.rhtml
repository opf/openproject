<% if @project.issue_categories.any? %>
<table class="list">
	<thead>
	<th><%= l(:label_issue_category) %></th>
	<th><%= l(:field_assigned_to) %></th>
	<th style="width:15%"></th>
	<th style="width:15%"></th>
	</thead>
	<tbody>
<% for category in @project.issue_categories %>
	<% unless category.new_record? %>
	<tr class="<%= cycle 'odd', 'even' %>">
    <td><%=h(category.name) %></td>
    <td><%=h(category.assigned_to.name) if category.assigned_to %></td>
    <td align="center"><%= link_to_if_authorized l(:button_edit), { :controller => 'issue_categories', :action => 'edit', :id => category }, :class => 'icon icon-edit' %></td>
    <td align="center"><%= link_to_if_authorized l(:button_delete), {:controller => 'issue_categories', :action => 'destroy', :id => category}, :method => :post, :class => 'icon icon-del' %></td>
	</tr>
	<% end %>
<% end %>
    </tbody>
</table>
<% else %>
<p class="nodata"><%= l(:label_no_data) %></p>
<% end %>

<p><%= link_to_if_authorized l(:label_issue_category_new), :controller => 'projects', :action => 'add_issue_category', :id => @project %></p>
