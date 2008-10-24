<% if @deliveries %>
<% form_tag({:action => 'edit', :tab => 'notifications'}) do %>

<div class="box tabular settings">
<p><label><%= l(:setting_mail_from) %></label>
<%= text_field_tag 'settings[mail_from]', Setting.mail_from, :size => 60 %></p>

<p><label><%= l(:setting_bcc_recipients) %></label>
<%= check_box_tag 'settings[bcc_recipients]', 1, Setting.bcc_recipients? %>
<%= hidden_field_tag 'settings[bcc_recipients]', 0 %></p>

<p><label><%= l(:setting_plain_text_mail) %></label>
<%= check_box_tag 'settings[plain_text_mail]', 1, Setting.plain_text_mail? %>
<%= hidden_field_tag 'settings[plain_text_mail]', 0 %></p>
</div>

<fieldset class="box" id="notified_events"><legend><%=l(:text_select_mail_notifications)%></legend>
<% @notifiables.each do |notifiable| %>
  <label><%= check_box_tag 'settings[notified_events][]', notifiable, Setting.notified_events.include?(notifiable) %>
  <%= l_or_humanize(notifiable, :prefix => 'label_') %></label><br />
<% end %>
<%= hidden_field_tag 'settings[notified_events][]', '' %>
<p><%= check_all_links('notified_events') %></p>
</fieldset>

<fieldset class="box"><legend><%= l(:setting_emails_footer) %></legend>
<%= text_area_tag 'settings[emails_footer]', Setting.emails_footer, :class => 'wiki-edit', :rows => 5 %>
</fieldset>

<div style="float:right;">
<%= link_to l(:label_send_test_email), :controller => 'admin', :action => 'test_email' %>
</div>

<%= submit_tag l(:button_save) %>
<% end %>
<% else %>
<div class="nodata">
<%= simple_format(l(:text_email_delivery_not_configured)) %>
</div>
<% end %>
