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

class Message < ActiveRecord::Base
  generator_for :subject, :method => :next_subject
  generator_for :content, :method => :next_content
  generator_for :board, :method => :generate_board

  def self.next_subject
    @last_subject ||= 'A Message'
    @last_subject.succ!
    @last_subject
  end

  def self.next_content
    @last_content ||= 'Some content here'
    @last_content.succ!
    @last_content
  end

  def self.generate_board
    Board.generate!
  end
end
