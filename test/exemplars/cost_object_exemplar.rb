CostObject.class_eval do
  generator_for :subject, "Cost Subject"
  generator_for :project, :method => :next_project
  generator_for :author, :method => :next_author
  generator_for :description, "Some cost subject"
  generator_for :fixed_date, Date.today
  
  def self.next_project
    Project.last.id || Project.generate!.id
  end

  def self.next_author
    User.first
  end
end