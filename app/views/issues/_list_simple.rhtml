<% if issues && issues.any? %>
<% form_tag({}) do %>
	<table class="list issues">		
		<thead><tr>
		<th>#</th>
		<th><%=l(:field_tracker)%></th>
		<th><%=l(:field_subject)%></th>
		</tr></thead>
		<tbody>	
		<% for issue in issues %>
		<tr id="issue-<%= issue.id %>" class="hascontextmenu <%= cycle('odd', 'even') %> <%= css_issue_classes(issue) %>">
			<td class="id">
			    <%= check_box_tag("ids[]", issue.id, false, :style => 'display:none;') %>
				<%= link_to issue.id, :controller => 'issues', :action => 'show', :id => issue %>
			</td>
			<td><%=h issue.project.name %> - <%= issue.tracker.name %><br />
                <%= issue.status.name %> - <%= format_time(issue.updated_on) %></td>
			<td class="subject">
                <%= link_to h(issue.subject), :controller => 'issues', :action => 'show', :id => issue %>
            </td>
		</tr>
		<% end %>
		</tbody>
	</table>
<% end %>
<% else %>
	<p class="nodata"><%= l(:label_no_data) %></p>
<% end %>
