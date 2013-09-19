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

class Journal::CostObjectJournal < ActiveRecord::Base

  # include ActiveModel::ForbiddenAttributesProtection

  self.table_name = "cost_object_journals"

  belongs_to :journal

  # attr_accessible :project_id, :author_id, :subject, :description, :fixed_date, :created_on

  # acts_as_journalized

  # acts_as_journalized :event_type => 'cost-object',
  #   :event_title => Proc.new {|o| "#{l(:label_cost_object)} ##{o.journaled.id}: #{o.subject}"},
  #   :event_url => Proc.new {|o| {:controller => 'cost_objects', :action => 'show', :id => o.journaled.id}},
  #   :activity_type => superclass.plural_name,
  #   :activity_find_options => {:include => [:project, :author]},
  #   :activity_timestamp => "#{table_name}.updated_on",
  #   :activity_author_key => :author_id,
  #   :activity_permission => :view_cost_objects

  @@journaled_attributes = [:project_id,
                            :author_id,
                            :subject,
                            :description,
                            :fixed_date]

  def journaled_attributes
    attributes.symbolize_keys.select{|k,_| @@journaled_attributes.include? k}
  end
end
