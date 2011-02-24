#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class DocumentObserver < ActiveRecord::Observer
  def after_create(document)
    if Setting.notified_events.include?('document_added')
      document.recipients.each do |recipient|
        Mailer.deliver_document_added(document, recipient)
      end
    end
  end
end
