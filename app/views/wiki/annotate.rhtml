<div class="contextual">
<%= link_to(l(:button_edit), {:action => 'edit', :page => @page.title}, :class => 'icon icon-edit') %>
<%= link_to(l(:label_history), {:action => 'history', :page => @page.title}, :class => 'icon icon-history') %>
</div>

<h2><%= @page.pretty_title %></h2>

<p>
<%= l(:label_version) %> <%= link_to @annotate.content.version, :action => 'index', :page => @page.title, :version => @annotate.content.version %>
<em>(<%= @annotate.content.author ? @annotate.content.author.name : "anonyme" %>, <%= format_time(@annotate.content.updated_on) %>)</em>
</p>

<% colors = Hash.new {|k,v| k[v] = (k.size % 12) } %>

<table class="filecontent annotate CodeRay ">
<tbody>
<% line_num = 1 %>
<% @annotate.lines.each do |line| -%>
<tr class="bloc-<%= colors[line[0]] %>">
    <th class="line-num"><%= line_num %></th>
    <td class="revision"><%= link_to line[0], :controller => 'wiki', :action => 'index', :id => @project, :page => @page.title, :version => line[0] %></td>
    <td class="author"><%= h(line[1]) %></td>
    <td class="line-code"><pre><%=h line[2] %></pre></td>
</tr>
<% line_num += 1 %>
<% end -%>
</tbody>
</table>

<% content_for :header_tags do %>
<%= stylesheet_link_tag 'scm' %>
<% end %>
