<% if @project.boards.any? %>
<table class="list">
	<thead><th><%= l(:label_board) %></th><th><%= l(:field_description) %></th><th style="width:15%"></th><th style="width:15%"></th><th style="width:15%"></th></thead>
	<tbody>
<% @project.boards.each do |board|
	next if board.new_record? %>
	<tr class="<%= cycle 'odd', 'even' %>">
    <td><%=h board.name %></td>
    <td><%=h board.description %></td>
    <td align="center">
    <% if authorize_for("boards", "edit") %>
    <%= link_to image_tag('2uparrow.png', :alt => l(:label_sort_highest)), {:controller => 'boards', :action => 'edit', :project_id => @project, :id => board, :position => 'highest'}, :method => :post, :title => l(:label_sort_highest) %>
    <%= link_to image_tag('1uparrow.png', :alt => l(:label_sort_higher)), {:controller => 'boards', :action => 'edit', :project_id => @project, :id => board, :position => 'higher'}, :method => :post, :title => l(:label_sort_higher) %> -
    <%= link_to image_tag('1downarrow.png', :alt => l(:label_sort_lower)), {:controller => 'boards', :action => 'edit', :project_id => @project, :id => board, :position => 'lower'}, :method => :post, :title => l(:label_sort_lower) %>
    <%= link_to image_tag('2downarrow.png', :alt => l(:label_sort_lowest)), {:controller => 'boards', :action => 'edit', :project_id => @project, :id => board, :position => 'lowest'}, :method => :post, :title => l(:label_sort_lowest) %>
    <% end %>
    </td>    
    <td align="center"><%= link_to_if_authorized l(:button_edit), {:controller => 'boards', :action => 'edit', :project_id => @project, :id => board}, :class => 'icon icon-edit' %></td>
    <td align="center"><%= link_to_if_authorized l(:button_delete), {:controller => 'boards', :action => 'destroy', :project_id => @project, :id => board}, :confirm => l(:text_are_you_sure), :method => :post, :class => 'icon icon-del' %></td>
	</tr>
<% end %>
    </tbody>
</table>
<% else %>
<p class="nodata"><%= l(:label_no_data) %></p>
<% end %>

<p><%= link_to_if_authorized l(:label_board_new), {:controller => 'boards', :action => 'new', :project_id => @project} %></p>
