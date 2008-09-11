<% form_tag({}, :id => 'query_form') do %>
<% if @query.new_record? %>
    <h2><%= l(:label_calendar) %></h2>
    <fieldset id="filters"><legend><%= l(:label_filter_plural) %></legend>
    <%= render :partial => 'queries/filters', :locals => {:query => @query} %>
    </fieldset>
<% else %>
    <h2><%=h @query.name %></h2>
    <% html_title @query.name %>
<% end %>

<fieldset id="date-range"><legend><%= l(:label_date_range) %></legend>
    <%= select_month(@month, :prefix => "month", :discard_type => true) %>
    <%= select_year(@year, :prefix => "year", :discard_type => true) %>
</fieldset>

<p style="float:right; margin:0px;">
<%= link_to_remote ('&#171; ' + (@month==1 ? "#{month_name(12)} #{@year-1}" : "#{month_name(@month-1)}")), 
                        {:update => "content", :url => { :year => (@month==1 ? @year-1 : @year), :month =>(@month==1 ? 12 : @month-1) }},
                        {:href => url_for(:action => 'calendar', :year => (@month==1 ? @year-1 : @year), :month =>(@month==1 ? 12 : @month-1))}
                        %> |
<%= link_to_remote ((@month==12 ? "#{month_name(1)} #{@year+1}" : "#{month_name(@month+1)}") + ' &#187;'), 
                        {:update => "content", :url => { :year => (@month==12 ? @year+1 : @year), :month =>(@month==12 ? 1 : @month+1) }},
                        {:href => url_for(:action => 'calendar', :year => (@month==12 ? @year+1 : @year), :month =>(@month==12 ? 1 : @month+1))}
                        %>
</p>

<p class="buttons">
<%= link_to_remote l(:button_apply), 
                   { :url => { :set_filter => (@query.new_record? ? 1 : nil) },
                     :update => "content",
                     :with => "Form.serialize('query_form')"
                   }, :class => 'icon icon-checked' %>
                   
<%= link_to_remote l(:button_clear),
                   { :url => { :set_filter => (@query.new_record? ? 1 : nil) }, 
                     :update => "content",
                   }, :class => 'icon icon-reload' if @query.new_record? %>
</p>
<% end %>

<%= error_messages_for 'query' %>
<% if @query.valid? %>
<%= render :partial => 'common/calendar', :locals => {:calendar => @calendar} %>

<%= image_tag 'arrow_from.png' %>&nbsp;&nbsp;<%= l(:text_tip_task_begin_day) %><br />
<%= image_tag 'arrow_to.png' %>&nbsp;&nbsp;<%= l(:text_tip_task_end_day) %><br />
<%= image_tag 'arrow_bw.png' %>&nbsp;&nbsp;<%= l(:text_tip_task_begin_end_day) %><br />
<% end %>

<% content_for :sidebar do %>
    <%= render :partial => 'issues/sidebar' %>
<% end %>

<% html_title(l(:label_calendar)) -%>
