def get_project(project_name = nil)
  if project_name.blank?
    project = @project
  else
    project = Project.find_by_name(project_name)
  end
end

def initialize_story_params(project, user = User.find(:first))
  story = HashWithIndifferentAccess.new(Story.new.attributes)
  story['project_id'] = project.id
  story['tracker_id'] = Story.trackers.first
  story['author_id']  = user.id
  story
end

def initialize_task_params(project, story, user = User.find(:first))
  params = HashWithIndifferentAccess.new
  params['project_id'] = project.id
  params['tracker_id'] = Task.tracker
  params['author_id']  = user.id
  params['parent_issue_id']  = story.id
  params['status_id'] = IssueStatus.find(:first).id
  params
end

def initialize_impediment_params(project, sprint, user = User.find(:first))
  params = HashWithIndifferentAccess.new(Task.new.attributes)
  params['project_id'] = project.id
  params['tracker_id'] = Task.tracker
  params['author_id']  = user.id
  params['fixed_version_id'] = sprint.id
  params['status_id'] = IssueStatus.find(:first).id
  params
end

def task_position(task)
  p1 = task.story.tasks.select{|t| t.id == task.id}[0].rank
  p2 = task.rank
  p1.should == p2
  return p1
end

def story_position(story)
  p1 = Story.backlog(story.project, story.fixed_version_id).select{|s| s.id == story.id}[0].rank
  p2 = story.rank
  p1.should == p2

  Story.at_rank(story.project_id, story.fixed_version_id, p1).id.should == story.id
  return p1
end

def logout
  visit url_for(:controller => 'account', :action=>'logout')
  @user = nil
end
