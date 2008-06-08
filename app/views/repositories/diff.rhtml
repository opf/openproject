<h2><%= l(:label_revision) %> <%= format_revision(@rev) %> <%= @path.gsub(/^.*\//, '') %></h2>

<!-- Choose view type -->
<% form_tag({ :controller => 'repositories', :action => 'diff'}, :method => 'get') do %>
  <% params.each do |k, p| %>
    <% if k != "type" %>
      <%= hidden_field_tag(k,p) %>
    <% end %>
    <% end %>
  <p><label><%= l(:label_view_diff) %></label>
  <%= select_tag 'type', options_for_select([[l(:label_diff_inline), "inline"], [l(:label_diff_side_by_side), "sbs"]], @diff_type), :onchange => "if (this.value != '') {this.form.submit()}" %></p>
<% end %>

<% cache(@cache_key) do -%>
<%= render :partial => 'common/diff', :locals => {:diff => @diff, :diff_type => @diff_type} %>
<% end -%>

<p class="other-formats">
<%= l(:label_export_to) %>
<span><%= link_to 'Unified diff', params.merge(:format => 'diff') %></span>
</p>

<% html_title(with_leading_slash(@path), 'Diff') -%>

<% content_for :header_tags do %>
<%= stylesheet_link_tag "scm" %>
<% end %>
