<% form_tag({:action => 'edit', :tab => 'authentication'}) do %>

<div class="box tabular settings">
<p><label><%= l(:setting_login_required) %></label>
<%= check_box_tag 'settings[login_required]', 1, Setting.login_required? %><%= hidden_field_tag 'settings[login_required]', 0 %></p>

<p><label><%= l(:setting_autologin) %></label>
<%= select_tag 'settings[autologin]', options_for_select( [[l(:label_disabled), "0"]] + [1, 7, 30, 365].collect{|days| [lwr(:actionview_datehelper_time_in_words_day, days), days.to_s]}, Setting.autologin) %></p>

<p><label><%= l(:setting_self_registration) %></label>
<%= select_tag 'settings[self_registration]',
      options_for_select( [[l(:label_disabled), "0"],
                           [l(:label_registration_activation_by_email), "1"],
                           [l(:label_registration_manual_activation), "2"],
                           [l(:label_registration_automatic_activation), "3"]
                          ], Setting.self_registration ) %></p>

<p><label><%= l(:label_password_lost) %></label>
<%= check_box_tag 'settings[lost_password]', 1, Setting.lost_password? %><%= hidden_field_tag 'settings[lost_password]', 0 %></p>
</div>

<div style="float:right;">
    <%= link_to l(:label_ldap_authentication), :controller => 'auth_sources', :action => 'list' %>
</div>

<%= submit_tag l(:button_save) %>
<% end %>
