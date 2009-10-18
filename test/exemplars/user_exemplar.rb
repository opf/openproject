class User < ActiveRecord::Base
  generator_for :login, :method => :next_email
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
