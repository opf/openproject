<% diff = Redmine::UnifiedDiff.new(diff, :type => diff_type, :max_lines => Setting.diff_max_lines_displayed.to_i) -%>
<% diff.each do |table_file| -%>
<div class="autoscroll">
<% if diff_type == 'sbs' -%>
<table class="filecontent CodeRay">
<thead>
<tr><th colspan="4" class="filename"><%= table_file.file_name %></th></tr>
</thead>
<tbody>
<% prev_line_left, prev_line_right = nil, nil -%>
<% table_file.keys.sort.each do |key| -%>
<% if prev_line_left && prev_line_right && (table_file[key].nb_line_left != prev_line_left+1) && (table_file[key].nb_line_right != prev_line_right+1) -%>
<tr class="spacing">
<th class="line-num">...</th><td></td><th class="line-num">...</th><td></td>
<% end -%>
<tr>
  <th class="line-num"><%= table_file[key].nb_line_left %></th>
  <td class="line-code <%= table_file[key].type_diff_left %>">
    <pre><%=to_utf8 table_file[key].line_left %></pre>
  </td>
  <th class="line-num"><%= table_file[key].nb_line_right %></th>
  <td class="line-code <%= table_file[key].type_diff_right %>">
    <pre><%=to_utf8 table_file[key].line_right %></pre>
  </td>
</tr>
<% prev_line_left, prev_line_right = table_file[key].nb_line_left.to_i, table_file[key].nb_line_right.to_i -%>
<% end -%>
</tbody>
</table>

<% else -%>
<table class="filecontent CodeRay">
<thead>
<tr><th colspan="3" class="filename"><%= table_file.file_name %></th></tr>
</thead>
<tbody>
<% prev_line_left, prev_line_right = nil, nil -%>
<% table_file.keys.sort.each do |key, line| %>
<% if prev_line_left && prev_line_right && (table_file[key].nb_line_left != prev_line_left+1) && (table_file[key].nb_line_right != prev_line_right+1) -%>
<tr class="spacing">
<th class="line-num">...</th><th class="line-num">...</th><td></td>
</tr>
<% end -%>
<tr>
  <th class="line-num"><%= table_file[key].nb_line_left %></th>
  <th class="line-num"><%= table_file[key].nb_line_right %></th>
  <% if table_file[key].line_left.empty? -%>
  <td class="line-code <%= table_file[key].type_diff_right %>">
    <pre><%=to_utf8 table_file[key].line_right %></pre>
  </td>
  <% else -%>
  <td class="line-code <%= table_file[key].type_diff_left %>">
    <pre><%=to_utf8 table_file[key].line_left %></pre>
  </td>
  <% end -%>
</tr>
<% prev_line_left = table_file[key].nb_line_left.to_i if table_file[key].nb_line_left.to_i > 0 -%>
<% prev_line_right = table_file[key].nb_line_right.to_i if table_file[key].nb_line_right.to_i > 0 -%>
<% end -%>
</tbody>
</table>
<% end -%>

</div>
<% end -%>

<%= l(:text_diff_truncated) if diff.truncated? %>
