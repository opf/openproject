#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class RemoveNoisyMessageJournals < ActiveRecord::Migration
  def self.up
    noisy_keys = %w[last_reply_id replies_count]

    MessageJournal.find_each(:batch_size => 100 ) do |j|
      if (j.changes.keys | noisy_keys).sort == noisy_keys
        j.destroy
      elsif (j.changes.keys & noisy_keys).count > 0
        noisy_keys.each{ |k| j.changes.delete(k) }
        j.save!
      end
    end
  end

  def self.down
    # no-op as the pointers shouldn't be journaled in the first time
  end
end
