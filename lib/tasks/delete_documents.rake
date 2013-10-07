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
  namespace :documents do
    class Document < ActiveRecord::Base
      belongs_to :project
      belongs_to :category, :class_name => "DocumentCategory", :foreign_key => "category_id"
    end

    desc "Removes all documents"
    task :delete => :environment do |task|
      try_delete_documents
    end

    def try_delete_documents
      begin
        if !$stdout.isatty || user_agrees
          Document.destroy_all
          Attachment.where(:container_type => ['Document']).destroy_all
        end
      rescue
        raise "Cannot delete documents! There may be migrations missing...?"
      end
    end

    def user_agrees
      questions = []

      questions << "CAUTION: This rake task will delete ALL documents!"
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
