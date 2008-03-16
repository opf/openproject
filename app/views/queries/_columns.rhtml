<% content_tag 'fieldset', :id => 'columns', :style => (query.has_default_columns? ? 'display:none;' : nil) do %>
<legend><%= l(:field_column_names) %></legend>

<%= hidden_field_tag 'query[column_names][]', '', :id => nil %>
<table>
	<tr>
		<td><%= select_tag 'available_columns',
		          options_for_select((query.available_columns - query.columns).collect {|column| [column.caption, column.name]}),
		          :multiple => true, :size => 10, :style => "width:150px" %>
		</td>
		<td align="center" valign="middle">
			<input type="button" value="--&gt;"
			 onclick="moveOptions(this.form.available_columns, this.form.selected_columns);" /><br />
			<input type="button" value="&lt;--"
			 onclick="moveOptions(this.form.selected_columns, this.form.available_columns);" />
		</td>
		<td><%= select_tag 'query[column_names][]',
		          options_for_select(@query.columns.collect {|column| [column.caption, column.name]}),
		          :id => 'selected_columns', :multiple => true, :size => 10, :style => "width:150px" %>
		</td>
	</tr>
</table>
<% end %>

<% content_for :header_tags do %>
<%= javascript_include_tag 'select_list_move' %>
<% end %>
