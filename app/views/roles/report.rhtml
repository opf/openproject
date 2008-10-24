<h2><%=l(:label_permissions_report)%></h2>

<% form_tag({:action => 'report'}, :id => 'permissions_form') do %>
<%= hidden_field_tag 'permissions[0]', '', :id => nil %>
<table class="list">
<thead>
    <tr>
    <th><%=l(:label_permissions)%></th>
    <% @roles.each do |role| %>
    <th>
        <%= content_tag(role.builtin? ? 'em' : 'span', h(role.name)) %>
        <%= link_to_function(image_tag('toggle_check.png'), "toggleCheckboxesBySelector('input.role-#{role.id}')",
                                                            :title => "#{l(:button_check_all)}/#{l(:button_uncheck_all)}") %>
    </th>
    <% end %>
    </tr>
</thead>
<tbody>
<% perms_by_module = @permissions.group_by {|p| p.project_module.to_s} %>
<% perms_by_module.keys.sort.each do |mod| %>
    <% unless mod.blank? %>
        <tr><%= content_tag('th', l_or_humanize(mod, :prefix => 'project_module_'), :colspan => (@roles.size + 1), :align => 'left') %></tr>
    <% end %>
    <% perms_by_module[mod].each do |permission| %>
        <tr class="<%= cycle('odd', 'even') %> permission-<%= permission.name %>">
        <td>
            <%= link_to_function(image_tag('toggle_check.png'), "toggleCheckboxesBySelector('.permission-#{permission.name} input')",
                                                                :title => "#{l(:button_check_all)}/#{l(:button_uncheck_all)}") %>
            <%= l_or_humanize(permission.name, :prefix => 'permission_') %>
        </td>
        <% @roles.each do |role| %>
        <td align="center">
        <% if role.setable_permissions.include? permission %>
          <%= check_box_tag "permissions[#{role.id}][]", permission.name, (role.permissions.include? permission.name), :id => nil, :class => "role-#{role.id}" %>
        <% end %>
        </td>
        <% end %>
        </tr>
    <% end %>
<% end %>
</tbody>
</table>
<p><%= check_all_links 'permissions_form' %></p>
<p><%= submit_tag l(:button_save) %></p>
<% end %>
