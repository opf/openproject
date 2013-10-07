#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

namespace :migrations do
  namespace :attachments do
    desc "Removes all attachments from versions and projects"
    task :delete_from_projects_and_versions => :environment do |task|
      try_delete_attachments_from_projects_and_versions
    end

    def try_delete_attachments_from_projects_and_versions
      begin
        Attachment.where(:container_type => ['Version','Project']).destroy_all if !$stdout.isatty || user_agrees
      rescue
        raise "Cannot delete attachments from projects and versions! There may be migrations missing...?"
      end
    end

    def user_agrees
      questions = []

      questions << "CAUTION: This rake task will delete ALL attachments attached to versions or projects!"
      questions << "DISCLAIMER: This is the final warning: You're going to lose information!"

      return false unless ask_question(questions[0]) && ask_question(questions[1])

      puts "Delete all attachments attached to projects or versions..."

      true
    end

    def ask_question(question)
      puts "\n\n"
      puts question
      puts "\nDo you want to continue? [y/N]"

      STDIN.gets.chomp == 'y'
    end
  end
end
