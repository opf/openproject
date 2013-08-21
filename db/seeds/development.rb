# set some sensible defaults:
include Redmine::I18n

#sensible shortcut: Create the default data in english
begin
  set_language_if_valid('en')
  Redmine::DefaultData::Loader.load(current_language)
  puts "Default configuration data loaded."
rescue Redmine::DefaultData::DataAlreadyLoaded => error
  puts "Redmine Default-Data already loaded"
end

# Careful: The seeding recreates the seeded project before it runs, so any changes on the seeded project will be lost.
puts "Creating seeded project..."
if delete_me=Project.find_by_identifier("seeded_project")
  delete_me.destroy
end

project = Project.create(name: "Seeded Project",
                         identifier: "seeded_project",
                         description: Faker::Lorem.paragraph(5),
                         types: Type.all,
                         is_public: true
                        )

# this will fail rather miserably, when there are no statuses present
statuses = IssueStatus.all
# don't bother with milestones, too difficult to handle all cases
types = project.types.all.reject{|type| type.is_milestone?}

project.enabled_module_names += ["timelines"]

# create a default timeline that shows all our planning elements
timeline = Timeline.create()
timeline.project = project
timeline.name = "Sample Timeline"
timeline.options.merge!({zoom_factor: ["4"]})
timeline.save



print "Creating issues and planning-elements..."
20.times do |count|
  login = "#{Faker::Name.first_name}#{rand(10000)}"

  user = User.find_by_login(login)

  unless user
    user = User.new()
    user.tap do |u|
        u.login = login
        u.firstname = Faker::Name.first_name
        u.lastname  = Faker::Name.last_name
        u.mail      = Faker::Internet.email
        u.save
    end
  end

  ## let every user create some issues...

  rand(10).times do
    print "."
    issue = Issue.create!(project: project,
                          author: user,
                          status: statuses.sample,
                          subject: Faker::Lorem.words(8).join(" "),
                          description: Faker::Lorem.paragraph(5, true,3),
                          type: types.sample
    )

  end



  rand(30).times do
    print "."
    start_date = rand(90).days.from_now
    due_date   = start_date + 5.day + rand(30).days


    element = PlanningElement.create!(project: project,
                                      author: user,
                                      status: statuses.sample,
                                      subject: Faker::Lorem.words(5).join(" "),
                                      description: Faker::Lorem.paragraph(5, true,3),
                                      type: types.sample,
                                      start_date: start_date,
                                      due_date: due_date)
    rand(5).times do
      print "."
      sub_start_date = rand(start_date..due_date)
      sub_due_date   = rand(sub_start_date..due_date)
      child_element = PlanningElement.create!(project: project,
                                              parent: element,
                                              author: user,
                                              status: statuses.sample,
                                              subject: Faker::Lorem.words(5).join(" "),
                                              description: Faker::Lorem.paragraph(5, true,3),
                                              type: types.sample,
                                              start_date: sub_start_date,
                                              due_date: sub_due_date)
    end


  end



end
print "done."
puts "\n"
puts "#{PlanningElement.where(:project_id => project.id).count} planning_elements created."
puts "#{Issue.where(:project_id => project.id).count} issues created."
puts "Creating seeded project...done."