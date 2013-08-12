#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class DocumentsMailer < UserMailer

  def document_added(user, document)
    @document = document

    open_project_headers 'Project' => @document.project.identifier,
                         'Type'    => 'Document'

    with_locale_for(user) do
      subject = "[#{@document.project.name}] #{t(:label_document_new)}: #{@document.title}"
      mail :to => user.mail, :subject => subject
    end
  end

  def attachments_added(user, attachments)
    container = attachments.first.container

    @added_to     = "#{Document.model_name.human}: #{container.title}"
    @added_to_url = url_for(:controller => '/documents', :action => 'show', :id => container.id)

    super
  end

end


