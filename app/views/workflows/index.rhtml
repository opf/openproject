<h2><%=l(:label_workflow)%></h2>

<% if @workflow_counts.empty? %>
<p class="nodata"><%= l(:label_no_data) %></p>
<% else %>
<table class="list">
<thead>
    <tr>
    <th></th>
    <% @workflow_counts.first.last.each do |role, count| %>
    <th>
        <%= content_tag(role.builtin? ? 'em' : 'span', h(role.name)) %>
    </th>
    
    <% end %>
    </tr>
</thead>
<tbody>
<% @workflow_counts.each do |tracker, roles| -%>
<tr class="<%= cycle('odd', 'even') %>">
  <td><%= h tracker %></td>
  <% roles.each do |role, count| -%>
    <td align="center">
      <%= link_to((count > 1 ? count : image_tag('false.png')), {:action => 'edit', :role_id => role, :tracker_id => tracker}, :title => l(:button_edit)) %>
    </td>
  <% end -%>
</tr>
<% end -%>
</tbody>
</table>
<% end %>
