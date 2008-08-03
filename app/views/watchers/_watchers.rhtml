<div class="contextual">
<%= link_to_remote l(:button_add), 
                   :url => {:controller => 'watchers',
                            :action => 'new',
                            :object_type => watched.class.name.underscore,
                            :object_id => watched} if User.current.allowed_to?(:add_issue_watchers, @project) %>
</div>

<p><strong><%= l(:label_issue_watchers) %></strong></p>
<%= watchers_list(watched) %>

<% unless @watcher.nil? %>
<% remote_form_for(:watcher, @watcher, 
                   :url => {:controller => 'watchers',
                            :action => 'new',
                            :object_type => watched.class.name.underscore,
                            :object_id => watched},
                   :method => :post,
                   :html => {:id => 'new-watcher-form'}) do |f| %>
<p><%= f.select :user_id, (watched.addable_watcher_users.collect {|m| [m.name, m.id]}), :prompt => true %>

<%= submit_tag l(:button_add) %>
<%= toggle_link l(:button_cancel), 'new-watcher-form'%></p>
<% end %>
<% end %>
