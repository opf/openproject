<div class="contextual">
<%= link_to_if_authorized l(:button_edit), {:controller => 'documents', :action => 'edit', :id => @document}, :class => 'icon icon-edit', :accesskey => accesskey(:edit) %>
<%= link_to_if_authorized l(:button_delete), {:controller => 'documents', :action => 'destroy', :id => @document}, :confirm => l(:text_are_you_sure), :method => :post, :class => 'icon icon-del' %>
</div>

<h2><%=h @document.title %></h2>

<p><em><%=h @document.category.name %><br />
<%= format_date @document.created_on %></em></p>
<div class="wiki">
<%= textilizable @document.description, :attachments => @document.attachments %>
</div>

<h3><%= l(:label_attachment_plural) %></h3>
<%= link_to_attachments @document %>

<% if authorize_for('documents', 'add_attachment') %>
<p><%= link_to l(:label_attachment_new), {}, :onclick => "Element.show('add_attachment_form'); Element.hide(this); Element.scrollTo('add_attachment_form'); return false;",
                                             :id => 'attach_files_link' %></p>
  <% form_tag({ :controller => 'documents', :action => 'add_attachment', :id => @document }, :multipart => true, :id => "add_attachment_form", :style => "display:none;") do %>
  <div class="box">
  <p><%= render :partial => 'attachments/form' %></p>
  </div>
  <%= submit_tag l(:button_add) %>
  <% end %> 
<% end %>

<% html_title @document.title -%>
