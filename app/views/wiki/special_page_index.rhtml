<h2><%= l(:label_index_by_title) %></h2>

<% if @pages.empty? %>
<p class="nodata"><%= l(:label_no_data) %></p>
<% end %>

<%= render_page_hierarchy(@pages_by_parent_id) %>

<% content_for :sidebar do %>
  <%= render :partial => 'sidebar' %>
<% end %>

<% unless @pages.empty? %>
<p class="other-formats">
<%= l(:label_export_to) %>
<span><%= link_to 'Atom', {:controller => 'projects', :action => 'activity', :id => @project, :show_wiki_pages => 1, :format => 'atom', :key => User.current.rss_key}, :class => 'feed' %></span>
<span><%= link_to 'HTML', {:action => 'special', :page => 'export'} %></span>
</p>
<% end %>

<% content_for :header_tags do %>
<%= auto_discovery_link_tag(:atom, :controller => 'projects', :action => 'activity', :id => @project, :show_wiki_pages => 1, :format => 'atom', :key => User.current.rss_key) %>
<% end %>
