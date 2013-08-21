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

class Journal::MessageJournal < ActiveRecord::Base
  self.table_name = "message_journals"

  belongs_to :journal

  @@journaled_attributes = [:board_id,
                            :parent_id,
                            :subject,
                            :content,
                            :author_id,
                            :replies_count,
                            :last_reply_id,
                            :sticky]

  def journaled_attributes
    attributes.symbolize_keys.select{|k,_| @@journaled_attributes.include? k}
  end

end
