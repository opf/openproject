class Backlog
  attr_accessor :sprint
  attr_accessor :stories

  def self.product_backlog(project, limit = nil)
    new(:stories => Story.backlog(project, nil, :limit => limit))
  end

  def self.sprint_backlogs(project)
    Sprint.open_sprints(project).map { |sprint| new(:stories => sprint.stories, :sprint => sprint) }
  end

  def initialize(options = {})
    options = options.with_indifferent_access
    @sprint = options['sprint']
    @stories = options['stories']
  end

  def updated_on
    @stories.max_by { |s| s.updated_on }.try(:updated_on)
  end
end
