# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
module DevelopmentData
  class ForumsSeeder < Seeder
    PROJECT_IDENTIFIER = "dev-forums"
    CONTENT_FILE = Rails.root.join("app/seeders/development_data/forums.yml")
    MINUTES_BETWEEN_REPLIES = 40

    def seed_data!
      print_status " ↳ Creating development forums..."

      project = Project.find_by!(identifier: PROJECT_IDENTIFIER)
      project.enabled_module_names = project.enabled_module_names | %w[forums]

      without_notifications do
        YAML.load_file(CONTENT_FILE).fetch("forums").each { seed_forum(project, it) }
      end
    end

    def applicable?
      Project.find_by(identifier: PROJECT_IDENTIFIER)&.forums&.none? || false
    end

    private

    def seed_forum(project, data)
      forum = project.forums.create!(name: data["name"], description: data["description"])
      data["topics"].each { seed_topic(forum, it) }
      forum.reset_counters!
    end

    def seed_topic(forum, data) # rubocop:disable Metrics/AbcSize
      started_at = data["days_ago"].days.ago
      topic = create_message(forum:, subject: data["subject"], author: data["author"], content: data["content"],
                             created_at: started_at, sticky: data["sticky"])

      replied_at = data["replies"].each_with_index.map do |reply, index|
        message = create_message(forum:, parent: topic, subject: "RE: #{topic.subject}", author: reply["author"],
                                 content: reply["content"],
                                 created_at: started_at + ((index + 1) * MINUTES_BETWEEN_REPLIES).minutes)
        seed_work_package(message, reply["work_package"]) if reply["work_package"]
        message.created_at
      end

      # Replying and locking stamp the topic with the time of seeding, which would scramble the activity sorts.
      topic.update_columns(locked: data["locked"] || false,
                           updated_at: replied_at.last || started_at,
                           sticked_on: (started_at if data["sticky"]))
    end

    def seed_work_package(message, data) # rubocop:disable Metrics/AbcSize
      type = Type.find_by!(name: data["type"])
      project = message.project
      project.project_types.create!(type:, variant: type.default_variant) unless project.enabled_types.include?(type)

      Messages::CreateWorkPackageService
        .new(user: message.author, message:)
        .call(work_package_params: { type_id: type.id, subject: message.root.subject, description: message.content })
        .on_failure { raise "Could not seed a work package from message #{message.id}: #{it.message}" }
    end

    def create_message(author:, created_at:, sticky: false, **)
      Message.create!(author: User.find_by!(login: author), created_at:, updated_at: created_at, sticky: sticky || false, **)
    end
  end
end
