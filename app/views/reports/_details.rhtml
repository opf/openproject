<% if @statuses.empty? or rows.empty? %>
    <p><i><%=l(:label_no_data)%></i></p>
<% else %>
<% col_width = 70 / (@statuses.length+3) %>
<table class="list">
<thead><tr>
<th style="width:25%"></th>
<% for status in @statuses %>
<th style="width:<%= col_width %>%"><%= status.name %></th>
<% end %>
<th align="center" style="width:<%= col_width %>%"><strong><%=l(:label_open_issues_plural)%></strong></th>
<th align="center" style="width:<%= col_width %>%"><strong><%=l(:label_closed_issues_plural)%></strong></th>
<th align="center" style="width:<%= col_width %>%"><strong><%=l(:label_total)%></strong></th>
</tr></thead>
<tbody>
<% for row in rows %>
<tr class="<%= cycle("odd", "even") %>">
  <td><%= link_to row.name, :controller => 'issues', :action => 'index', :project_id => ((row.is_a?(Project) ? row : @project)), 
                                                :set_filter => 1, 
                                                "#{field_name}" => row.id %></td>
  <% for status in @statuses %>
    <td align="center"><%= aggregate_link data, { field_name => row.id, "status_id" => status.id }, 
                                                :controller => 'issues', :action => 'index', :project_id => ((row.is_a?(Project) ? row : @project)), 
                                                :set_filter => 1, 
                                                "status_id" => status.id, 
                                                "#{field_name}" => row.id %></td>
  <% end %>
  <td align="center"><%= aggregate_link data, { field_name => row.id, "closed" => 0 },
                                                :controller => 'issues', :action => 'index', :project_id => ((row.is_a?(Project) ? row : @project)), 
                                                :set_filter => 1, 
                                                "#{field_name}" => row.id,
                                                "status_id" => "o" %></td>
  <td align="center"><%= aggregate_link data, { field_name => row.id, "closed" => 1 },
                                                :controller => 'issues', :action => 'index', :project_id => ((row.is_a?(Project) ? row : @project)), 
                                                :set_filter => 1, 
                                                "#{field_name}" => row.id,
                                                "status_id" => "c" %></td>
  <td align="center"><%= aggregate_link data, { field_name => row.id },
                                                :controller => 'issues', :action => 'index', :project_id => ((row.is_a?(Project) ? row : @project)), 
                                                :set_filter => 1, 
                                                "#{field_name}" => row.id,
                                                "status_id" => "*" %></td>  
</tr>
<% end %>
</tbody>
</table>
<% end
  reset_cycle %>