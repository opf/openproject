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

module Redmine
  class Notifiable < Struct.new(:name, :parent)

    def to_s
      name
    end

    # TODO: Plugin API for adding a new notification?
    def self.all
      notifications = []
      notifications << Notifiable.new('issue_added')
      notifications << Notifiable.new('issue_updated')
      notifications << Notifiable.new('issue_note_added', 'issue_updated')
      notifications << Notifiable.new('issue_status_updated', 'issue_updated')
      notifications << Notifiable.new('issue_priority_updated', 'issue_updated')
      notifications << Notifiable.new('news_added')
      notifications << Notifiable.new('news_comment_added')
      notifications << Notifiable.new('file_added')
      notifications << Notifiable.new('message_posted')
      notifications << Notifiable.new('wiki_content_added')
      notifications << Notifiable.new('wiki_content_updated')
      notifications
    end
  end
end
