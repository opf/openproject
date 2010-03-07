class CostObject < ActiveRecord::Base
  generator_for :subject, "Cost Subject"
  generator_for :project_id, :method => :next_project
  generator_for :author_id, :method => :next_author
  generator_for :description, "Some cost subject"
  generator_for :fixed_date, Date.today
  
  def self.next_project
    Project.count || Project.generate!.id
  end

  def self.next_author
    AnonymousUser.current.id || AnonymousUser.new.save!.id
  end
end