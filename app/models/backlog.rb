class Backlog
  unloadable

  attr_accessor :sprint
  attr_accessor :stories

  def self.owner_backlogs(project, limit = nil)
    versions = Sprint.apply_to(project).open.displayed_right(project)#project.shared_versions.open.displayed_right(project)#Version.open.displayed_right(project).sort_by{|v| v.name}
    versions.map{ |version| new(:stories => Story.backlog(project, version.id, :limit => limit), :owner_backlog => true, :sprint => version)}
  end

  def self.sprint_backlogs(project)
    sprints = Sprint.apply_to(project).open.displayed_left(project).order_by_date
    sprints.map{ |sprint| new(:stories => sprint.stories, :sprint => sprint) }
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
