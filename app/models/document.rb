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

class Document < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :project
  belongs_to :category, :class_name => "DocumentCategory", :foreign_key => "category_id"
  acts_as_attachable :delete_permission => :manage_documents

  acts_as_journalized :event_title => Proc.new {|o| "#{Document.model_name.human}: #{o.title}"},
      :event_url => Proc.new {|o| {:controller => '/documents', :action => 'show', :id => o.journal.journable_id}},
      :event_author => (Proc.new do |o|
        o.journal.journable.attachments.find(:first, :order => "#{Attachment.table_name}.created_on ASC").try(:author)
      end)

  acts_as_searchable :columns => ['title', "#{table_name}.description"], :include => :project

  validates_presence_of :project, :title, :category
  validates_length_of :title, :maximum => 60

  scope :visible, lambda {|*args| { :include => :project,
                                    :conditions => Project.allowed_to_condition(args.first || User.current, :view_documents) } }
  scope :with_attachments, includes(:attachments).where("attachments.container_id is not NULL" )

  after_initialize :set_default_category

  # TODO: category_id needed for forms, can we make that differently?
  attr_accessible :title, :description, :project, :category, :category_id

  safe_attributes 'category_id', 'title', 'description'

  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_documents, project)
  end

  def set_default_category
    self.category ||= DocumentCategory.default if new_record?
  end

  def updated_on
    unless @updated_on
      # attachments has a default order that conflicts with `created_on DESC`
      # #reorder removes that default order but rather than #unscoped keeps the
      # scoping by this document
      a = attachments.reorder('created_on DESC').first
      @updated_on = (a && a.created_on) || created_on
    end
    @updated_on
  end
end
