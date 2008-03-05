<h2><%= l(:label_index_by_date) %></h2>

<% if @pages.empty? %>
<p class="nodata"><%= l(:label_no_data) %></p>
<% end %>

<% @pages_by_date.keys.sort.reverse.each do |date| %>
<h3><%= format_date(date) %></h3>
<ul>
<% @pages_by_date[date].each do |page| %>
    <li><%= link_to page.pretty_title, :action => 'index', :page => page.title %></li>
<% end %>
</ul>
<% end %>

<% content_for :sidebar do %>
  <%= render :partial => 'sidebar' %>
<% end %>

<% unless @pages.empty? %>
<p class="other-formats">
<%= l(:label_export_to) %>
<span><%= link_to 'Atom', {:controller => 'projects', :action => 'activity', :id => @project, :show_wiki_pages => 1, :format => 'atom', :key => User.current.rss_key}, :class => 'feed' %></span>
<span><%= link_to 'HTML', {:action => 'special', :page => 'export'}, :class => 'html' %></span>
</p>
<% end %>

<% content_for :header_tags do %>
<%= auto_discovery_link_tag(:atom, :controller => 'projects', :action => 'activity', :id => @project, :show_wiki_pages => 1, :format => 'atom', :key => User.current.rss_key) %>
<% end %>
