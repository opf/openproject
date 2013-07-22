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

class Project < ActiveRecord::Base
  generator_for :name, :method => :next_name
  generator_for :identifier, :method => :next_identifier_from_object_daddy
  generator_for :enabled_modules, :method => :all_modules
  generator_for :types, :method => :next_type

  def self.next_name
    @last_name ||= 'Project 0'
    @last_name.succ!
    @last_name
  end

  # Project#next_identifier is defined on Redmine
  def self.next_identifier_from_object_daddy
    @last_identifier ||= 'project-0000'
    @last_identifier.succ!
    @last_identifier
  end

  def self.all_modules
    [].tap do |modules|
      Redmine::AccessControl.available_project_modules.each do |name|
        modules << EnabledModule.new(:name => name.to_s)
      end
    end
  end

  def self.next_type
    [Type.generate!]
  end
end
