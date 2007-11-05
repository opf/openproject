<div class="contextual">
<%= link_to_if_authorized l(:label_query_new), {:controller => 'queries', :action => 'new', :project_id => @project}, :class => 'icon icon-add' %>
</div>

<h2><%= l(:label_query_plural) %></h2>

<% if @queries.empty? %>
  <p><i><%=l(:label_no_data)%></i></p>
<% else %>
  <table class="list">
  <% @queries.each do |query| %>
    <tr class="<%= cycle('odd', 'even') %>">
      <td>
        <%= link_to query.name, :controller => 'issues', :action => 'index', :project_id => @project, :query_id => query %>
      </td>
      <td align="right">
        <small>
        <% if query.editable_by?(User.current) %>    
        <%= link_to l(:button_edit), {:controller => 'queries', :action => 'edit', :id => query}, :class => 'icon icon-edit' %>
        <%= link_to l(:button_delete), {:controller => 'queries', :action => 'destroy', :id => query}, :confirm => l(:text_are_you_sure), :method => :post, :class => 'icon icon-del' %>
        </small>
      <% end %>
      </td>
    </tr>
  <% end %>
  </table>
<% end %>
