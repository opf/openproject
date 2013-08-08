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

class Journal < ActiveRecord::Base
  self.table_name = "journals"

  attr_accessible :journaled_type, :journaled_id, :activity_type, :version, :notes, :user_id

  # Make sure each journaled model instance only has unique version ids
  validates_uniqueness_of :version, :scope => [:journaled_id, :journaled_type]

  belongs_to :user

  before_save :save_data

  # Scopes to all journals excluding the initial journal - useful for change
  # logs like the history on issue#show
  scope "changing", :conditions => ["version > 1"]

  def journaled
    journalized_object_type.find(journaled_id)
  end

  def changed_data=(changed_attributes)
    data.update_attributes changed_attributes
  end

  # In conjunction with the included Comparable module, allows comparison of journal records
  # based on their corresponding version numbers, creation timestamps and IDs.
  def <=>(other)
    [version, created_at, id].map(&:to_i) <=> [other.version, other.created_at, other.id].map(&:to_i)
  end

  # Returns whether the version has a version number of 1. Useful when deciding whether to ignore
  # the version during reversion, as initial versions have no serialized changes attached. Helps
  # maintain backwards compatibility.
  def initial?
    version < 2
  end

  # The anchor number for html output
  def anchor
    version - 1
  end

  # Possible shortcut to the associated project
  def project
    if journaled.respond_to?(:project)
      journaled.project
    elsif journaled.is_a? Project
      journaled
    else
      nil
    end
  end

  def editable_by?(user)
    journaled.journal_editable_by?(user)
  end

  def details
    changes
  end

  alias_method :changed_data, :details

  def new_value_for(prop)
    details[prop.to_s].last if details.keys.include? prop.to_s
  end

  def old_value_for(prop)
    details[prop.to_s].first if details.keys.include? prop.to_s
  end

  def data
    @data ||= "Journal::#{journaled_type}".constantize.find_by_journal_id(id)
  end

  private

  def save_data
    data.save! unless data.nil?
  end

  def changes
    return {} if data.nil?

    if @changes.nil?
      @changes = {}

      if predecessor.nil?
        @changes = data.journaled_attributes.select{|_,v| !v.nil?}
                                            .inject({}) { |h, (k, v)| h[k] = [(true if Float(v) rescue false) ? 0 : nil, v]; h }
      else
        predecessor_data = predecessor.data.journaled_attributes
          data.journaled_attributes.select{|k,v| v != predecessor_data[k]}.each do |k, v|
            @changes[k] = [predecessor_data[k], v]
          end
        end
    end

    @changes
  end

  def predecessor
    @predecessor ||= Journal.where("journaled_type = ? AND journaled_id = ? AND created_at <= ? AND id != ?",
                                   journaled_type, journaled_id, created_at, id)
                            .order("created_at DESC")
                            .first
  end

  def journalized_object_type
    "#{journaled_type.gsub('Journal', '')}".constantize
  end
end
