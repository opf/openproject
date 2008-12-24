<div class="contextual">
<%= link_to_if_authorized l(:label_attachment_new), {:controller => 'projects', :action => 'add_file', :id => @project}, :class => 'icon icon-add' %>
</div>

<h2><%=l(:label_attachment_plural)%></h2>

<% delete_allowed = User.current.allowed_to?(:manage_files, @project) %>

<table class="list">
  <thead><tr>
    <%= sort_header_tag('filename', :caption => l(:field_filename)) %>
    <%= sort_header_tag('created_on', :caption => l(:label_date), :default_order => 'desc') %>
    <%= sort_header_tag('size', :caption => l(:field_filesize), :default_order => 'desc') %>
    <%= sort_header_tag('downloads', :caption => l(:label_downloads_abbr), :default_order => 'desc') %>
    <th>MD5</th>
    <th></th>
  </tr></thead>
  <tbody>
<% @containers.each do |container| %>	
  <% next if container.attachments.empty? -%>
	<% if container.is_a?(Version) -%>
  <tr><th colspan="6" align="left"><span class="icon icon-package"><b><%=h container %></b></span></th></tr>
	<% end -%>
  <% container.attachments.each do |file| %>		
  <tr class="<%= cycle("odd", "even") %>">
    <td><%= link_to_attachment file, :download => true, :title => file.description %></td>
    <td align="center"><%= format_time(file.created_on) %></td>
    <td align="center"><%= number_to_human_size(file.filesize) %></td>
    <td align="center"><%= file.downloads %></td>
    <td align="center"><small><%= file.digest %></small></td>
    <td align="center">
    <%= link_to(image_tag('delete.png'), {:controller => 'attachments', :action => 'destroy', :id => file},
																				 :confirm => l(:text_are_you_sure), :method => :post) if delete_allowed %>
    </td>
  </tr>		
  <% end
  reset_cycle %>
<% end %>
  </tbody>
</table>

<% html_title(l(:label_attachment_plural)) -%>
