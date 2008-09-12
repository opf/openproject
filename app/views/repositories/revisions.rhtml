<div class="contextual">
<% form_tag({:action => 'revision', :id => @project}) do %>
<%= l(:label_revision) %>: <%= text_field_tag 'rev', @rev, :size => 5 %>
<%= submit_tag 'OK' %>
<% end %>
</div>

<h2><%= l(:label_revision_plural) %></h2>

<%= render :partial => 'revisions', :locals => {:project => @project, :path => '', :revisions => @changesets, :entry => nil }%>

<p class="pagination"><%= pagination_links_full @changeset_pages,@changeset_count %></p>

<% content_for :header_tags do %>
<%= stylesheet_link_tag "scm" %>
<%= auto_discovery_link_tag(:atom, params.merge({:format => 'atom', :page => nil, :key => User.current.rss_key})) %>
<% end %>

<p class="other-formats">
<%= l(:label_export_to) %>
<span><%= link_to 'Atom', {:format => 'atom', :key => User.current.rss_key}, :class => 'feed' %></span>
</p>

<% html_title(l(:label_revision_plural)) -%>
