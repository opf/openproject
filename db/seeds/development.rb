# only seed a new project, if it hasn't already run
puts "Creating seeded project..."
if delete_me=Project.find_by_identifier("seeded_project")
  delete_me.destroy
end

project = FactoryGirl.create(:public_project, name: "Seeded Project", identifier: "seeded_project", description: Faker::Lorem.paragraph(5))
project.types << Type.all
project.save

# this will fail rather miserably, when there are no statuses present
statuses = IssueStatus.all
types = project.types.all
puts "Creating seeded project...done."

puts "Creating issues ..."
20.times do |count|
  login = "#{Faker::Name.first_name}#{rand(10000)}"

  user = User.find_by_login(login)

  unless user
    user = FactoryGirl.create(:user,
                              login: login,
                              firstname: Faker::Name.first_name,
                              lastname: Faker::Name.last_name,
                              mail: Faker::Internet.email)
  end

  ## let every user about 5 issues...

  rand(30).times do
    print "."
    issue = Issue.create!(project: project,
                          author: user,
                          status: statuses.sample,
                          subject: Faker::Lorem.words(8).join(" "),
                          description: Faker::Lorem.paragraph(5, true,3),
                          type: types.sample
    )

  end

  rand(20).times do
    start_date = rand(20).days.from_now
    due_date   = start_date + rand(20).days

    element = PlanningElement.create!(project: project,
                                     author: user,
                                     status: statuses.sample,
                                     subject: Faker::Lorem.words(5).join(" "),
                                     description: Faker::Lorem.paragraph(5, true,3),
                                     type: types.sample,
                                     start_date: start_date,
                                     due_date: due_date)
    rand(5).times do
      offset = start_date
      element = PlanningElement.create!(project: project,
                                        author: user,
                                        status: statuses.sample,
                                        subject: Faker::Lorem.words(5).join(" "),
                                        description: Faker::Lorem.paragraph(5, true,3),
                                        type: types.sample,
                                        start_date: start_date,
                                        due_date: due_date)
    end


  end


end

puts "\n"
puts "#{project.work_packages.count} issues created."
