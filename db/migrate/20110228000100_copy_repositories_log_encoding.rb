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

class CopyRepositoriesLogEncoding < ActiveRecord::Migration
  def self.up
    encoding = Setting.commit_logs_encoding.to_s.strip
    encoding = encoding.blank? ? 'UTF-8' : encoding
    Repository.find(:all).each do |repo|
      scm = repo.scm_name
      case scm
        when 'Subversion', 'Mercurial', 'Git', 'Filesystem'
          repo.update_attribute(:log_encoding, nil)
        else
          repo.update_attribute(:log_encoding, encoding)
      end
    end
  end

  def self.down
  end
end
