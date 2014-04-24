#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
