def initialize_story_params(project, user = User.find(:first))
  story = HashWithIndifferentAccess.new(Story.new.attributes)
  story['type_id'] = Story.types.first

  # unsafe attributes that will not be used directly but added for your
  # convenience
  story['project_id'] = project.id
  story['author_id']  = user.id
  story['project'] = project
  story['author']  = user
  story
end

def initialize_task_params(project, story, user = User.find(:first))
  params = HashWithIndifferentAccess.new
  params['type_id'] = Task.type
  params['parent_id']  = story.id if story
  params['status_id'] = Status.find(:first).id

  # unsafe attributes that will not be used directly but added for your
  # convenience
  params['project_id'] = project.id
  params['author_id']  = user.id
  params['project'] = project
  params['author']  = user
  params
end

def initialize_work_package_params(project, type = Type.find(:first), parent = nil, user = User.find(:first))
  params = HashWithIndifferentAccess.new
  params['type_id'] = type.id
  params['parent_id']  = parent.id if parent
  params['status_id'] = Status.find(:first).id

  # unsafe attributes that will not be used directly but added for your
  # convenience
  params['project_id'] = project.id
  params['author_id']  = user.id
  params['project'] = project
  params['author']  = user
  params
end

def initialize_impediment_params(project, sprint, user = User.find(:first))
  params = HashWithIndifferentAccess.new(Task.new.attributes)
  params['type_id'] = Task.type
  params['fixed_version_id'] = sprint.id
  params['status_id'] = Status.find(:first).id

  # unsafe attributes that will not be used directly but added for your
  # convenience
  params['project_id'] = project.id
  params['author_id']  = user.id
  params['project'] = project
  params['author']  = user
  params
end

def task_position(task)
  p1 = task.story.tasks.select{|t| t.id == task.id}[0].rank
  p2 = task.rank
  p1.should == p2
  return p1
end

def story_position(story)
  p1 = Story.sprint_backlog(story.project, story.fixed_version).detect{ |s| s.id == story.id }.rank
  p2 = story.rank
  p1.should == p2

  Story.at_rank(story.project_id, story.fixed_version_id, p1).id.should == story.id
  return p1
end

def logout
  visit url_for(:controller => '/account', :action=>'logout')
  @user = nil
end
