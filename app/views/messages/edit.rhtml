<h2><%= link_to h(@board.name), :controller => 'boards', :action => 'show', :project_id => @project, :id => @board %> &#187; <%=h @message.subject %></h2>

<% form_for :message, @message, :url => {:action => 'edit'}, :html => {:multipart => true, :id => 'message-form'} do |f| %>
  <%= render :partial => 'form', :locals => {:f => f, :replying => !@message.parent.nil?} %>
  <%= submit_tag l(:button_save) %>
  <%= link_to_remote l(:label_preview), 
                     { :url => { :controller => 'messages', :action => 'preview', :board_id => @board },
                       :method => 'post',
                       :update => 'preview',
                       :with => "Form.serialize('message-form')",
                       :complete => "Element.scrollTo('preview')"
                     }, :accesskey => accesskey(:preview) %>
<% end %>
<div id="preview" class="wiki"></div>
