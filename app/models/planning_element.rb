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

class PlanningElement < WorkPackage
  unloadable

  include ActiveModel::ForbiddenAttributesProtection

  has_many :alternate_dates, :class_name  => "AlternateDate",
                             :foreign_key => 'planning_element_id',
                             :autosave    => true,
                             :dependent   => :delete_all

  accepts_nested_attributes_for_apis_for :parent,
                                         :planning_element_status,
                                         :type,
                                         :project

  # This SQL only works when there are no two updates in the same
  # millisecond. As soon as updates happen in rapid succession, multiple
  # instances of one planning element are returned.

  SQL_FOR_AT = {
    :select => "#{PlanningElement.quoted_table_name}.id,
                #{PlanningElement.quoted_table_name}.subject,
                #{PlanningElement.quoted_table_name}.description,
                #{PlanningElement.quoted_table_name}.planning_element_status_comment,
                #{AlternateDate.quoted_table_name  }.start_date,
                #{AlternateDate.quoted_table_name  }.due_date,
                #{PlanningElement.quoted_table_name}.parent_id,
                #{PlanningElement.quoted_table_name}.project_id,
                #{PlanningElement.quoted_table_name}.responsible_id,
                #{PlanningElement.quoted_table_name}.planning_element_type_id,
                #{PlanningElement.quoted_table_name}.planning_element_status_id,
                #{PlanningElement.quoted_table_name}.created_at,
                #{PlanningElement.quoted_table_name}.deleted_at,
                #{AlternateDate.quoted_table_name  }.updated_at",
    :joins => "LEFT JOIN (
                  SELECT
                    #{AlternateDate.quoted_table_name}.planning_element_id,
                    MAX(#{AlternateDate.quoted_table_name}.updated_at) AS updated_at
                  FROM #{AlternateDate.quoted_table_name}
                  WHERE
                    #{AlternateDate.quoted_table_name}.created_at <= ?
                  GROUP BY
                    #{AlternateDate.quoted_table_name}.planning_element_id
                )  AS alternate_dates_sub
                  ON #{PlanningElement.quoted_table_name}.id = alternate_dates_sub.planning_element_id
              INNER JOIN
                #{AlternateDate.quoted_table_name}
                  ON #{AlternateDate.quoted_table_name}.planning_element_id = alternate_dates_sub.planning_element_id
                    AND #{AlternateDate.quoted_table_name}.updated_at = alternate_dates_sub.updated_at"

  }

  scope :visible, lambda {|*args| { :include => :project,
                                          :conditions => PlanningElement.visible_condition(args.first || User.current) } }

  scope :at_time, lambda { |time|
    {:select     => SQL_FOR_AT[:select],
     :conditions => ["(#{PlanningElement.quoted_table_name}.deleted_at IS NULL
                        OR #{PlanningElement.quoted_table_name}.deleted_at >= ?)", time],
     :joins      => sanitize_sql([SQL_FOR_AT[:joins], time]),
     :readonly   => true
    }
  }

  scope :for_projects, lambda { |projects|
    {:conditions => {:project_id => projects}}
  }

  # Used for activities list
  def title
    title = ''
    title << subject
    title << ' ('
    title << type.name << ' ' if type
    title << '*'
    title << id.to_s
    title << ')'
  end

  # Overriding Journal Class to provide extended information in activity view
  journal_class.class_eval do
    def event_title
      if initial?
        I18n.t("timelines.planning_element_creation", :title => journalized.title)
      else
        I18n.t("timelines.planning_element_update", :title => journalized.title)
      end
    end
  end

  def append_scenario_dates_to_journal
    changes = {}
    alternate_dates.each do |d|
      if d.scenario.present? && (!(alternate_date_changes = d.changes).empty? || d.marked_for_destruction?)
        ["start_date", "due_date"].each do |field|
          old_value = if (scenario_changes = alternate_date_changes["scenario_id"])
            scenario_changes.first.nil? ? nil : d.send(field)
          else
            alternate_date_changes[field].nil? ? d.send(field) : alternate_date_changes[field].first
          end
          new_value = d.marked_for_destruction? ? nil : d.send(field)
          changes.merge!({ "scenario_#{d.scenario.id}_#{field}" => [old_value, new_value] }) unless new_value == old_value
        end
      end
    end
    journal_changes.append_changes!(changes)
  end

  before_save :append_scenario_dates_to_journal

  after_save :update_parent_attributes
  after_save :create_alternate_date

  validates_presence_of :subject, :project

  validates_length_of :subject, :maximum => 255, :unless => lambda { |e| e.subject.blank? }

  def duration
    if start_date >= due_date
      1
    else
      due_date - start_date + 1
    end
  end

  def is_milestone?
    type && type.is_milestone?
  end

  validate do
    if self.due_date and self.start_date and self.due_date < self.start_date
      errors.add :due_date, :greater_than_start_date
    end

    if self.is_milestone?
      if self.due_date and self.start_date and self.start_date != self.due_date
        errors.add :due_date, :not_start_date
      end
    end

    if self.parent
      errors.add :parent, :cannot_be_milestone if parent.is_milestone?
      errors.add :parent, :cannot_be_in_another_project if parent.project != project
      errors.add :parent, :cannot_be_in_recycle_bin if parent.deleted?
    end

  end

  def leaf?
    self.children.count == 0
  end

  def all_scenarios
    project.scenarios.sort_by(&:id).map do |scenario|
      alternate_date = alternate_dates.to_a.find { |a| a.scenario_id.to_s == scenario.id.to_s }
      alternate_date ||= alternate_dates.build.tap { |ad| ad.scenario_id = scenario.id }
      PlanningElementScenario.new(alternate_date)
    end
  end

  def scenarios
    alternate_dates.scenaric.sort_by(&:scenario_id).map do |alternate_date|
      PlanningElementScenario.new(alternate_date)
    end
  end

  # Expecting pe_scenarios to be an Array of Hashes or a Hash of Hashes with
  # arbitrary keys following the following schema:
  #
  #   {
  #     'id' => 1,
  #     'start_date => '2012-01-01',
  #     'due_date' => '2012-01-03'
  #   }
  #
  # The id attribute is required. If both date fields are empty or missing, the
  # alternate date will be deleted. The alternate date will also be deleted,
  # when the "_destroy" key is present and set to "1".
  #
  # Other attributes will be silently ignored.
  #
  def scenarios=(pe_scenarios)
    pe_scenarios = pe_scenarios.values if pe_scenarios.is_a? Hash

    pe_scenarios.each do |pe_scenario|
      alternate_date = alternate_dates.to_a.find { |date| date.scenario_id.to_s == pe_scenario['id'].to_s }
      unless alternate_date
        if self.new_record?
          alternate_date = AlternateDate.new.tap { |ad| ad.scenario_id = pe_scenario['id'] }
          alternate_date.planning_element = self
          alternate_dates << alternate_date
        else
          alternate_date = alternate_dates.build.tap { |ad| ad.scenario_id = pe_scenario['id'] }
        end
      end

      if (pe_scenario['start_date'].blank? and pe_scenario['due_date'].blank?) or
          pe_scenario['_destroy'] == '1'
        alternate_date.mark_for_destruction
      else
        alternate_date.attributes = {'start_date' => pe_scenario['start_date'],
                                     'due_date'   => pe_scenario['due_date']}
      end
    end
  end

  def note
    @journal_notes
  end

  def note=(text)
    @journal_notes = text
  end

  def trash
    unless new_record? or self.deleted_at
      self.children.each{|child| child.trash}

      self.reload
      self.deleted_at = Time.now
      self.save!
    end
    freeze
  end

  def restore!
    unless parent && parent.deleted?
      self.deleted_at = nil
      self.save
    else
      raise "You cannot restore an element whose parent is deleted. Restore the parent first!"
    end
  end

  def deleted?
    !!read_attribute(:deleted_at)
  end

  # Aliasing the parent_issue_id methods here in order
  # to improve compatibility between
  # planning elments and issues
  alias_method :parent_issue_id, :parent_id

  # I am not sure why it is not possible to
  # alias_method :parent_issue_id=, :parent_id=
  def parent_issue_id=(arg)
    parent_id = arg
  end

  protected

  def update_parent_attributes
    if parent.present?
      parent.reload

      unless parent.children.without_deleted.empty?
        children = parent.children.without_deleted

        parent.start_date = [children.minimum(:start_date), children.minimum(:due_date)].reject(&:nil?).min
        parent.due_date   = [children.maximum(:start_date), children.maximum(:due_date)].reject(&:nil?).max

        if parent.changes.present?
          parent.note = I18n.t('timelines.planning_element_updated_automatically_by_child_changes', :child => "*#{id}")

          # Ancestors will be updated by parent's after_save hook.
          parent.save(:validate => false)
        end
      end
    end
  end

  def create_alternate_date
    if start_date_changed? or due_date_changed?
      alternate_dates.create(:start_date => start_date, :due_date => due_date)
    end
  end
end
