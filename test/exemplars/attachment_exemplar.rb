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
    @file = ActiveSupport::TestCase.mock_file
  end
end
