<% @entries.each do |entry| %>
<% tr_id = Digest::MD5.hexdigest(entry.path)
   depth = params[:depth].to_i %>
<tr id="<%= tr_id %>" class="<%= params[:parent_id] %> entry <%= entry.kind %>">
<td style="padding-left: <%=18 * depth%>px;" class="filename">
<% if entry.is_dir? %>
<span class="expander" onclick="<%=  remote_function :url => {:action => 'browse', :id => @project, :path => to_path_param(entry.path), :rev => @rev, :depth => (depth + 1), :parent_id => tr_id},
                  :update => { :success => tr_id },
                  :position => :after,
                  :success => "scmEntryLoaded('#{tr_id}')",
                  :condition => "scmEntryClick('#{tr_id}')"%>">&nbsp</span>
<% end %>
<%=  link_to h(entry.name),
          {:action => (entry.is_dir? ? 'browse' : 'changes'), :id => @project, :path => to_path_param(entry.path), :rev => @rev},
          :class => (entry.is_dir? ? 'icon icon-folder' : 'icon icon-file')%>
</td>
<td class="size"><%= (entry.size ? number_to_human_size(entry.size) : "?") unless entry.is_dir? %></td>
<% changeset = @project.repository.changesets.find_by_revision(entry.lastrev.identifier) if entry.lastrev && entry.lastrev.identifier %>
<td class="revision"><%= link_to(format_revision(entry.lastrev.name), :action => 'revision', :id => @project, :rev => entry.lastrev.identifier) if entry.lastrev && entry.lastrev.identifier %></td>
<td class="age"><%= distance_of_time_in_words(entry.lastrev.time, Time.now) if entry.lastrev && entry.lastrev.time %></td>
<td class="author"><%= changeset.nil? ? h(entry.lastrev.author.to_s.split('<').first) : changeset.author if entry.lastrev %></td>
<td class="comments"><%=h truncate(changeset.comments, 50) unless changeset.nil? %></td>
</tr>
<% end %>
