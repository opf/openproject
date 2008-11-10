<% form_tag({:controller => 'repositories', :action => 'diff', :id => @project, :path => to_path_param(path)}, :method => :get) do %>
<table class="list changesets">
<thead><tr>
<th>#</th>
<th></th>
<th></th>
<th><%= l(:label_date) %></th>
<th><%= l(:field_author) %></th>
<th><%= l(:field_comments) %></th>
</tr></thead>
<tbody>
<% show_diff = entry && entry.is_file? && revisions.size > 1 %>
<% line_num = 1 %>
<% revisions.each do |changeset| %>
<tr class="changeset <%= cycle 'odd', 'even' %>">
<td class="id"><%= link_to format_revision(changeset.revision), :action => 'revision', :id => project, :rev => changeset.revision %></td>
<td class="checkbox"><%= radio_button_tag('rev', changeset.revision, (line_num==1), :id => "cb-#{line_num}", :onclick => "$('cbto-#{line_num+1}').checked=true;") if show_diff && (line_num < revisions.size) %></td>
<td class="checkbox"><%= radio_button_tag('rev_to', changeset.revision, (line_num==2), :id => "cbto-#{line_num}", :onclick => "if ($('cb-#{line_num}').checked==true) {$('cb-#{line_num-1}').checked=true;}") if show_diff && (line_num > 1) %></td>
<td class="committed_on"><%= format_time(changeset.committed_on) %></td>
<td class="author"><%=h changeset.author %></td>
<td class="comments"><%= textilizable(truncate_at_line_break(changeset.comments)) %></td>
</tr>
<% line_num += 1 %>
<% end %>
</tbody>
</table>
<%= submit_tag(l(:label_view_diff), :name => nil) if show_diff %>
<% end %>
