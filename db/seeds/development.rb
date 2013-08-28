# set some sensible defaults:
include Redmine::I18n

# sensible shortcut: Create the default data in english
begin
  set_language_if_valid('en')
  Redmine::DefaultData::Loader.load(current_language)
  puts "Default configuration data loaded."
rescue Redmine::DefaultData::DataAlreadyLoaded
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

# create some custom fields and add them to the project
3.times do |count|
  cf = WorkPackageCustomField.create!(name: Faker::Lorem.words(2).join(" "),
                                      regexp: "",
                                      is_required: false,
                                      min_length: false,
                                      default_value: "",
                                      max_length: false,
                                      editable: true,
                                      possible_values: "",
                                      visible: true,
                                      field_format: "text")

  project.work_package_custom_fields << cf
end

# create a default timeline that shows all our planning elements
timeline = Timeline.create()
timeline.project = project
timeline.name = "Sample Timeline"
timeline.options.merge!({zoom_factor: ["4"]})
timeline.save

board = Board.create! project: project,
                      name: Faker::Lorem.words(2).join(" "),
                      description: Faker::Lorem.paragraph(5).slice(0, 255)

wiki = Wiki.create project: project, start_page: "Seed"

time_entry_activities = []

5.times do
  time_entry_activity = TimeEntryActivity.create name: Faker::Lorem.words(2).join(" ")

  time_entry_activity.save!
  time_entry_activities << time_entry_activity
end

Setting.enabled_scm = Setting.enabled_scm.dup << 'Filesystem' unless Setting.enabled_scm.include?('Filesystem')

repository = Repository::Filesystem.create! project: project,
                                            url: Faker::Internet.url()


print "Creating objects for..."
20.times do |count|
  login = "#{Faker::Name.first_name}#{rand(10000)}"

  puts
  print "...for user number #{count} (#{login})"

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

  puts ""
  print "......create issues"

  rand(10).times do
    print "."
    Issue.create!(project: project,
                  author: user,
                  status: statuses.sample,
                  subject: Faker::Lorem.words(8).join(" "),
                  description: Faker::Lorem.paragraph(5, true,3),
                  type: types.sample
    )

  end

  ## extend user's last issue
  created_issues = WorkPackage.find :all, conditions: { author_id: user.id }

  if !created_issues.empty?
    issue = created_issues.last

    ## add changesets

    2.times do |changeset_count|
      print "."
      changeset = Changeset.create(repository: repository,
                                   user: user,
                                   revision: issue.id * 10 + changeset_count,
                                   scmid: issue.id * 10 + changeset_count,
                                   user: user,
                                   work_packages: [issue],
                                   committer: Faker::Name.name,
                                   committed_on: Date.today,
                                   comments: Faker::Lorem.words(8).join(" "))

      5.times do
        print "."
        change = Change.create(action: Faker::Lorem.characters(1),
                               path: Faker::Internet.url)

        changeset.changes << change
      end

      repository.changesets << changeset

      changeset.save!

      rand(5).times do
        print "."
        changeset.reload

        changeset.committer = Faker::Name.name if rand(99).even?
        changeset.committed_on = Date.today + rand(999) if rand(99).even?
        changeset.comments = Faker::Lorem.words(8).join(" ") if rand(99).even?

        changeset.save!
      end
    end

    ## add time entries

    5.times do |time_entry_count|
      issue.time_entries << TimeEntry.create(project: project,
                                             user: user,
                                             work_package: issue,
                                             spent_on: Date.today + time_entry_count,
                                             activity: time_entry_activities.sample,
                                             hours: time_entry_count)
    end

    ## add attachments

    3.times do |attachment_count|
      issue.attachments << Attachment.new(author: user,
                                          filename: Faker::Lorem.words(8).join(" "),
                                          disk_filename: Faker::Lorem.words(8).join("_"))
    end

    ## add custom values

    project.work_package_custom_fields.each do |custom_field|
      issue.type.custom_fields << custom_field if !issue.type.custom_fields.include?(custom_field)
      issue.custom_values << CustomValue.new(custom_field: custom_field, value: Faker::Lorem.words(8).join(" "))
    end

    issue.type.save!
    issue.save!

    ## create some changes

    20.times do
      print "."
      issue.reload

      issue.status = statuses.sample if rand(99).even?
      issue.subject = Faker::Lorem.words(8).join(" ") if rand(99).even?
      issue.description = Faker::Lorem.paragraph(5, true,3) if rand(99).even?
      issue.type = types.sample if rand(99).even?

      issue.time_entries.each do |t|
        t.spent_on = Date.today + rand(100) if rand(99).even?
        t.activity = time_entry_activities.sample if rand(99).even?
        t.hours = rand(10) if rand(99).even?
      end

      issue.reload

      attachments = issue.attachments

      attachments.each do |a|
        issue.attachments.delete a if rand(99).even?
      end

      issue.reload

      issue.custom_values.each do |cv|
        cv.value = Faker::Code.isbn if rand(99).even?
      end

      issue.save!
    end
  end

  puts ""
  print "......create planning elements"

  rand(30).times do
    print "."
    start_date = rand(90).days.from_now
    due_date   = start_date + 5.day + rand(30).days
    child_element = nil


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

    [element, child_element].compact.each do |e|
      2.times do
        print "."
        e.reload

        e.status = statuses.sample if rand(99).even?
        e.subject = Faker::Lorem.words(8).join(" ") if rand(99).even?
        e.description = Faker::Lorem.paragraph(5, true,3) if rand(99).even?
        e.type = types.sample if rand(99).even?

        e.save!
      end
    end

  end

  ## create some messages

  puts ""
  print "......create messages"

  rand(30).times do
    print "."
    message = Message.create board: board,
                             author: user,
                             subject: Faker::Lorem.words(5).join(" "),
                             content: Faker::Lorem.paragraph(5, true, 3)

    rand(5).times do
      print "."
      Message.create board: board,
                     author: user,
                     subject: message.subject,
                     content: Faker::Lorem.paragraph(5, true, 3),
                     parent: message
    end
  end

  ## create some news

  puts ""
  print "......create news"

  rand(30).times do
    print "."
    news = News.create project: project,
                       author: user,
                       title: Faker::Lorem.characters(60),
                       summary: Faker::Lorem.paragraph(1, true, 3),
                       description: Faker::Lorem.paragraph(5, true, 3)

    ## create some journal entries

    rand(5).times do
      news.reload

      news.title = Faker::Lorem.words(5).join(" ") if rand(99).even?
      news.summary = Faker::Lorem.paragraph(1, true, 3) if rand(99).even?
      news.description = Faker::Lorem.paragraph(5, true, 3) if rand(99).even?

      news.save!
    end
  end

  ## create some wiki pages

  puts ""
  print "......create wikis"

  rand(5).times do
    print "."
    wiki_page = WikiPage.create wiki: wiki,
                                title: Faker::Lorem.words(5).join(" ")

    ## create some wiki contents

    rand(5).times do
      print "."
      wiki_content = WikiContent.create page: wiki_page,
                                        author: user,
                                        text: Faker::Lorem.paragraph(5, true, 3)

      ## create some journal entries

      rand(5).times do
        wiki_content.reload

        wiki_content.text = Faker::Lorem.paragraph(5, true, 3) if rand(99).even?

        wiki_content.save!
      end
    end
  end
end

print "done."
puts "\n"
puts "#{PlanningElement.where(:project_id => project.id).count} planning_elements created."
puts "#{Issue.where(:project_id => project.id).count} issues created."
puts "#{Message.joins(:board).where(boards: { :project_id => project.id }).count} messages created."
puts "#{News.where(:project_id => project.id).count} news created."
puts "#{WikiContent.joins(page: [ :wiki ]).where("wikis.project_id = ?", project.id).count} wiki contents created."
puts "#{TimeEntry.where(:project_id => project.id).count} time entries created."
puts "#{Changeset.joins(:repository).where(repositories: { :project_id => project.id }).count} changesets created."
puts "Creating seeded project...done."
