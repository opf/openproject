#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class RemoveNoisyAttachmentJournals < ActiveRecord::Migration
  def self.up
    AttachmentJournal.find_each(:batch_size => 100 ) do |j|
      if j.changes.keys == ["downloads"]
        j.destroy
      elsif j.changes.keys.include? "downloads"
        j.changes.delete("downloads")
        j.save!
      end
    end
  end

  def self.down
    # no-op as the downloads counter shouldn't be journaled in the first time
  end
end
