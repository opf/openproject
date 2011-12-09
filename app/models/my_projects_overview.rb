#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 Finn GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See LICENSE for more details.
#++

class MyProjectsOverview < ActiveRecord::Base
  unloadable

  DEFAULTS = {
    "left" => ["wiki", "projectdetails", "issuetracking"],
    "right" => ["members", "news"],
    "top" => [],
    "hidden" => [] }

  def initialize(attributes = nil)
    super

    if attributes.nil?
      DEFAULTS.each_pair do |k, v|
        self.send("#{k}=", v)
      end
    else
      not_provided = DEFAULTS.keys - attributes.keys.collect(&:to_s)

      not_provided.each do |k|
        self.send("#{k}=", [])
      end
    end
  end

  serialize :top
  serialize :left
  serialize :right
  serialize :hidden
  belongs_to :project

  validate :fields_are_arrays

  acts_as_attachable :delete_permission => :edit_project, :view_permission => :view_project

  def fields_are_arrays
    Array === top && Array === left && Array === right && Array === hidden
  end

  def save_custom_element(name, title, new_content)
    el = custom_elements.detect {|x| x.first == name}
    return unless el
    el[1] = title
    el[2] = new_content
    save
  end

  def new_custom_element
    idx = custom_elements.any? ? custom_elements.sort.last.first.next : "a"
    [idx, l(:label_custom_text), "h2. #{l(:info_custom_text)}"]
  end

  def elements
    top + left + right + hidden
  end

  def custom_elements
    elements.select {|x| x.respond_to? :to_ary }
  end

  def attachments_visible?(user)
    true
  end
end
