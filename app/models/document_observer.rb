#-- encoding: UTF-8
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

class DocumentObserver < ActiveRecord::Observer


  def after_create(document)

    return unless Notifier.notify?(:document_added)

    users = User.find_all_by_mails(document.recipients)
    users.each do |user|
      DocumentsMailer.document_added(user, document).deliver
    end
  end
end

