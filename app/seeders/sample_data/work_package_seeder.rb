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
module SampleData
  class WorkPackageSeeder

    def self.seed!(project)
      user = User.first
      statuses = Status.all
      repository = Repository.first
      time_entry_activities = TimeEntryActivity.all
      types = project.types.all.reject(&:is_milestone?)

      puts ''
      print ' ↳ Creating work_packages'

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
        work_package.type     = types.sample
        work_package.status   = statuses.sample
        work_package.priority = IssuePriority.all.sample
        work_package.save!
      end

      work_package = WorkPackage.last

      ## add changesets
      if repository
        2.times do |changeset_count|
          print '.'
          changeset = Changeset.create(repository: repository,
                                       user: user,
                                       revision: work_package.id * 10 + changeset_count,
                                       scmid: work_package.id * 10 + changeset_count,
                                       user: user,
                                       work_packages: [work_package],
                                       committer: Faker::Name.name,
                                       committed_on: Date.today,
                                       comments: Faker::Lorem.words(8).join(' '))

          5.times do
            print '.'
            change = Change.create(action: Faker::Lorem.characters(1),
                                   path: Faker::Internet.url)

            changeset.file_changes << change
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

        ## add time entries
        5.times do |time_entry_count|
          work_package.time_entries << TimeEntry.create(project: project,
                                                 user: user,
                                                 work_package: work_package,
                                                 spent_on: Date.today + time_entry_count,
                                                 activity: time_entry_activities.sample,
                                                 hours: time_entry_count)
        end

        ## add attachments
        3.times do |_attachment_count|
          attachment = Attachment.new(container: work_package,
                                      author: user,
                                      file: OpenProject::Files.create_uploaded_file(
                                        name: Faker::Lorem.words(8).join(' ')))
          attachment.save!

          work_package.attachments << attachment
        end

        ## add custom values
        project.work_package_custom_fields.each do |custom_field|
          work_package.type.custom_fields << custom_field if !work_package.type.custom_fields.include?(custom_field)
          work_package.custom_values << CustomValue.new(custom_field: custom_field,
                                                 value: Faker::Lorem.words(8).join(' '))
        end

        work_package.type.save!
        work_package.save!

        ## create some changes

        20.times do
          print '.'
          work_package.reload

          work_package.status = statuses.sample if rand(99).even?
          work_package.subject = Faker::Lorem.words(8).join(' ') if rand(99).even?
          work_package.description = Faker::Lorem.paragraph(5, true, 3) if rand(99).even?
          work_package.type = types.sample if rand(99).even?

          work_package.time_entries.each do |t|
            t.spent_on = Date.today + rand(100) if rand(99).even?
            t.activity = time_entry_activities.sample if rand(99).even?
            t.hours = rand(10) if rand(99).even?
          end

          work_package.reload

          attachments = work_package.attachments.select { |_a| rand(999) < 10 }
          work_package.attachments = work_package.attachments - attachments

          work_package.reload

          work_package.custom_values.each do |cv|
            cv.value = Faker::Code.isbn if rand(99).even?
          end

          work_package.save!
        end
      end
    end

  end
end
