#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require "#{Rails.root}/db/seeds/basic_setup"

user_count = ENV.fetch('SEED_USER_COUNT', 3).to_i

# Careful: The seeding recreates the seeded project before it runs, so any changes
# on the seeded project will be lost.
puts 'Creating seeded project...'
if delete_me = Project.find_by_identifier('seeded_project')
  delete_me.destroy
end

project = Project.create(name: 'Seeded Project',
                         identifier: 'seeded_project',
                         description: Faker::Lorem.paragraph(5),
                         types: Type.all,
                         is_public: true
                        )

# this will fail rather miserably, when there are no statuses present
statuses = Status.all
# don't bother with milestones, too difficult to handle all cases
types = project.types.all.reject(&:is_milestone?)

project.enabled_module_names += ['timelines']

# create some custom fields and add them to the project
3.times do |_count|
  cf = WorkPackageCustomField.create!(name: Faker::Lorem.words(2).join(' '),
                                      regexp: '',
                                      is_required: false,
                                      min_length: false,
                                      default_value: '',
                                      max_length: false,
                                      editable: true,
                                      possible_values: '',
                                      visible: true,
                                      field_format: 'text')

  project.work_package_custom_fields << cf
end

# create a default timeline that shows all our work packages
timeline = Timeline.create
timeline.project = project
timeline.name = 'Sample Timeline'
timeline.options.merge!(zoom_factor: ['4'])
timeline.save

board = Board.create! project: project,
                      name: Faker::Lorem.words(2).join(' '),
                      description: Faker::Lorem.paragraph(5).slice(0, 255)

wiki = Wiki.create project: project, start_page: 'Seed'

time_entry_activities = []

5.times do
  time_entry_activity = TimeEntryActivity.create name: Faker::Lorem.words(2).join(' ')

  time_entry_activity.save!
  time_entry_activities << time_entry_activity
end

repo_url_setting = OpenProject::Configuration['scm_filesystem_path_whitelist']
repository = if repo_url_setting.empty?
               puts <<-MESSAGE
* = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + =

Filesystem based repositories are not configured. No repository and no changeset will be created.

In case you want those, define whitelisted repositories in your configuration.yml.
See config/configuration.yml.example for details.

* = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + = * = + =

               MESSAGE

               nil
             else
               Setting.enabled_scm = (Setting.enabled_scm.dup << 'Filesystem').uniq

               repo_url = Dir.glob(repo_url_setting).first

               Repository::Filesystem.create! project: project,
                                              url: repo_url
             end

print 'Creating objects for...'
user_count.times do |count|
  login = "#{Faker::Name.first_name}#{rand(10000)}"

  puts
  print "...for user number #{count + 1}/#{user_count} (#{login})"

  user = User.find_by_login(login)

  unless user
    user = User.new
    user.tap do |u|
      u.login = login
      u.firstname = Faker::Name.first_name
      u.lastname  = Faker::Name.last_name
      u.mail      = Faker::Internet.email
      u.save
    end
  end

  ## let every user create some issues...

  puts ''
  print '......create issues'

  rand(50).times do
    print '.'
    work_package = WorkPackage.new(project: project,
                                   author: user,
                                   status: statuses.sample,
                                   subject: Faker::Lorem.words(8).join(' '),
                                   description: Faker::Lorem.paragraph(5, true, 3),
                                   start_date: s = Date.today - (25 - rand(50)).days,
                                   due_date: s + (1 + rand(120)).days
    )
    work_package.type = types.sample
    work_package.save!

  end

  ## extend user's last issue
  created_issues = WorkPackage.find :all, conditions: { author_id: user.id }

  if !created_issues.empty?
    issue = created_issues.last

    ## add changesets

    if repository
      2.times do |changeset_count|
        print '.'
        changeset = Changeset.create(repository: repository,
                                     user: user,
                                     revision: issue.id * 10 + changeset_count,
                                     scmid: issue.id * 10 + changeset_count,
                                     user: user,
                                     work_packages: [issue],
                                     committer: Faker::Name.name,
                                     committed_on: Date.today,
                                     comments: Faker::Lorem.words(8).join(' '))

        5.times do
          print '.'
          change = Change.create(action: Faker::Lorem.characters(1),
                                 path: Faker::Internet.url)

          changeset.changes << change
        end

        repository.changesets << changeset

        changeset.save!

        rand(5).times do
          print '.'
          changeset.reload

          changeset.committer = Faker::Name.name if rand(99).even?
          changeset.committed_on = Date.today + rand(999) if rand(99).even?
          changeset.comments = Faker::Lorem.words(8).join(' ') if rand(99).even?

          changeset.save!
        end
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

    3.times do |_attachment_count|
      attachment = Attachment.new(container: issue,
                                  author: user,
                                  file: OpenProject::Files.create_uploaded_file(
                                    name: Faker::Lorem.words(8).join(' ')))
      attachment.save!

      issue.attachments << attachment
    end

    ## add custom values

    project.work_package_custom_fields.each do |custom_field|
      issue.type.custom_fields << custom_field if !issue.type.custom_fields.include?(custom_field)
      issue.custom_values << CustomValue.new(custom_field: custom_field, value: Faker::Lorem.words(8).join(' '))
    end

    issue.type.save!
    issue.save!

    ## create some changes

    20.times do
      print '.'
      issue.reload

      issue.status = statuses.sample if rand(99).even?
      issue.subject = Faker::Lorem.words(8).join(' ') if rand(99).even?
      issue.description = Faker::Lorem.paragraph(5, true, 3) if rand(99).even?
      issue.type = types.sample if rand(99).even?

      issue.time_entries.each do |t|
        t.spent_on = Date.today + rand(100) if rand(99).even?
        t.activity = time_entry_activities.sample if rand(99).even?
        t.hours = rand(10) if rand(99).even?
      end

      issue.reload

      attachments = issue.attachments.select { |_a| rand(999) < 10 }
      issue.attachments = issue.attachments - attachments

      issue.reload

      issue.custom_values.each do |cv|
        cv.value = Faker::Code.isbn if rand(99).even?
      end

      issue.save!
    end
  end

  ## create some messages

  puts ''
  print '......create messages'

  rand(30).times do
    print '.'
    message = Message.create board: board,
                             author: user,
                             subject: Faker::Lorem.words(5).join(' '),
                             content: Faker::Lorem.paragraph(5, true, 3)

    rand(5).times do
      print '.'
      Message.create board: board,
                     author: user,
                     subject: message.subject,
                     content: Faker::Lorem.paragraph(5, true, 3),
                     parent: message
    end
  end

  ## create some news

  puts ''
  print '......create news'

  rand(30).times do
    print '.'
    news = News.create project: project,
                       author: user,
                       title: Faker::Lorem.characters(60),
                       summary: Faker::Lorem.paragraph(1, true, 3),
                       description: Faker::Lorem.paragraph(5, true, 3)

    ## create some journal entries

    rand(5).times do
      news.reload

      news.title = Faker::Lorem.words(5).join(' ').slice(0, 60) if rand(99).even?
      news.summary = Faker::Lorem.paragraph(1, true, 3) if rand(99).even?
      news.description = Faker::Lorem.paragraph(5, true, 3) if rand(99).even?

      news.save!
    end
  end

  ## create some wiki pages

  puts ''
  print '......create wikis'

  rand(5).times do
    print '.'
    wiki_page = WikiPage.create wiki: wiki,
                                title: Faker::Lorem.words(5).join(' ')

    ## create some wiki contents

    rand(5).times do
      print '.'
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

print 'done.'
puts "\n"
puts "#{WorkPackage.where(project_id: project.id).count} issues created."
puts "#{Message.joins(:board).where(boards: { project_id: project.id }).count} messages created."
puts "#{News.where(project_id: project.id).count} news created."
puts "#{WikiContent.joins(page: [:wiki]).where('wikis.project_id = ?', project.id).count} wiki contents created."
puts "#{TimeEntry.where(project_id: project.id).count} time entries created."
puts "#{Changeset.joins(:repository).where(repositories: { project_id: project.id }).count} changesets created."
puts 'Creating seeded project...done.'
