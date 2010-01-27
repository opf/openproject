class Wiki < ActiveRecord::Base
  generator_for :start_page => 'Start'
  generator_for :project, :method => :generate_project

  def self.generate_project
    Project.generate!
  end
end
