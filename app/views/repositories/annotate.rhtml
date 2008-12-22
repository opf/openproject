<h2><%= render :partial => 'navigation', :locals => { :path => @path, :kind => 'file', :revision => @rev } %></h2>

<p><%= render :partial => 'link_to_functions' %></p>

<% colors = Hash.new {|k,v| k[v] = (k.size % 12) } %>

<div class="autoscroll">
<table class="filecontent annotate CodeRay">
  <tbody>
    <% line_num = 1 %>
    <% syntax_highlight(@path, to_utf8(@annotate.content)).each_line do |line| %>
    <% revision = @annotate.revisions[line_num-1] %>
    <tr class="bloc-<%= revision.nil? ? 0 : colors[revision.identifier || revision.revision] %>">
      <th class="line-num"><%= line_num %></th>
      <td class="revision">
      <%= (revision.identifier ? link_to(format_revision(revision.identifier), :action => 'revision', :id => @project, :rev => revision.identifier) : format_revision(revision.revision)) if revision %></td>
      <td class="author"><%= h(revision.author.to_s.split('<').first) if revision %></td>
      <td class="line-code"><pre><%= line %></pre></td>
    </tr>
    <% line_num += 1 %>
    <% end %>
  </tbody>
</table>
</div>

<% html_title(l(:button_annotate)) -%>

<% content_for :header_tags do %>
<%= stylesheet_link_tag 'scm' %>
<% end %>
