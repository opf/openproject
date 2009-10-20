module ObjectDaddyHelpers
  # TODO: The gem or official version of ObjectDaddy doesn't set
  # protected attributes so they need to be wrapped.
  def User.generate_with_protected!(attributes={})
    user = User.spawn(attributes) do |user|
      user.login = User.next_login
      attributes.each do |attr,v|
        user.send("#{attr}=", v)
      end
    end
    user.save!
    user
  end

  # Generate the default Query
  def Query.generate_default!(attributes={})
    query = Query.spawn(attributes)
    query.name ||= '_'
    query.save!
    query
  end

  # Generate an issue for a project, using it's trackers
  def Issue.generate_for_project!(project, attributes={})
    issue = Issue.spawn(attributes) do |issue|
      issue.project = project
    end
    issue.tracker = project.trackers.first unless project.trackers.empty?
    issue.save!
    issue
  end

end
