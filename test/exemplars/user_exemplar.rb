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

class User < Principal
  generator_for :login, :method => :next_login
  generator_for :mail, :method => :next_email
  generator_for :firstname, :method => :next_firstname
  generator_for :lastname, :method => :next_lastname

  def self.next_login
    @gen_login ||= 'user1'
    @gen_login.succ!
    @gen_login
  end

  def self.next_email
    @last_email ||= 'user1'
    @last_email.succ!
    "#{@last_email}@example.com"
  end

  def self.next_firstname
    @last_firstname ||= 'Bob'
    @last_firstname.succ!
    @last_firstname
  end

  def self.next_lastname
    @last_lastname ||= 'Doe'
    @last_lastname.succ!
    @last_lastname
  end
end
