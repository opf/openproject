class Backlog
  unloadable

  attr_accessor :sprint
  attr_accessor :stories

  def self.owner_backlogs(project, limit = nil)
    stories = Story.backlog(project, nil, :limit => limit)
    [new(:stories => stories, :owner_backlog => true)]
  end

  def self.sprint_backlogs(project)
    Sprint.open_sprints(project).map { |sprint| new(:stories => sprint.stories, :sprint => sprint) }
  end

  def initialize(options = {})
    options = options.with_indifferent_access
    @sprint = options['sprint']
    @stories = options['stories']
    @owner_backlog = options['owner_backlog']
  end

  def updated_on
    @stories.max_by(&:updated_on).try(:updated_on)
  end

  def owner_backlog?
    !!@owner_backlog
  end

  def sprint_backlog?
    !owner_backlog?
  end
end
