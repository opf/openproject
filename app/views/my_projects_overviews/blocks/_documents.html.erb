<h3><%=l(:label_document_plural)%></h3>

<% project_ids = @user.projects.select {|p| @user.allowed_to?(:view_documents, p)}.collect(&:id) %>
<%= render(:partial => 'documents/document',
           :collection => Document.find(:all,
                         :limit => 10,
                         :order => "#{Document.table_name}.created_on DESC",
                         :conditions => "#{Document.table_name}.project_id in (#{project_ids.join(',')})",
                         :include => [:project])) unless project_ids.empty? %>