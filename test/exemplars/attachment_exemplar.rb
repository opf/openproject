class Attachment < ActiveRecord::Base
  generator_for :container, :method => :generate_project
  generator_for :file, :method => :generate_file
  generator_for :author, :method => :generate_author

  def self.generate_project
    Project.generate!
  end

  def self.generate_author
    User.generate_with_protected!
  end

  def self.generate_file
    @file = 'a_file.png'
    @file.stubs(:original_filename).returns('a_file.png')
    @file.stubs(:content_type).returns('image/png')
    @file.stubs(:read).returns(false)
    @file
  end
end
