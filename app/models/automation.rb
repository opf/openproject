# frozen_string_literal: true

class Automation < ApplicationRecord
  validates :name, length: { maximum: 255, minimum: 1 }
  validate :must_have_at_least_one_trigger
  validate :must_not_have_more_than_one_manual_trigger

  serialize :actions, coder: Automations::Actions::Serializer
  before_validation :ensure_manual_trigger

  has_and_belongs_to_many :status_conditions, class_name: "Status", join_table: :automations_statuses
  has_and_belongs_to_many :role_conditions, class_name: "Role", join_table: :automations_roles
  has_and_belongs_to_many :type_conditions, class_name: "Type", join_table: :automations_types
  has_and_belongs_to_many :project_conditions, class_name: "Project", join_table: :automations_projects

  has_many :triggers,
           -> { order(:position, :id) },
           class_name: "Automations::Triggers::Base",
           dependent: :destroy,
           inverse_of: :automation
  accepts_nested_attributes_for :triggers

  after_save :persist_conditions

  attribute :conditions
  define_attribute_method "conditions"

  acts_as_list

  scope :with_manual_trigger, -> {
    joins(:triggers).where(automation_triggers: { type: "Automations::Triggers::Manual" }).distinct
  }

  def initialize(*args)
    ret = super
    self.actions ||= []
    ret
  end

  def reload(*args)
    @conditions = nil
    super
  end

  def actions=(values)
    actions_will_change!
    super
  end

  def self.order_by_name
    order(:name)
  end

  def self.order_by_position
    order(:position)
  end

  def all_actions
    all_of(available_actions, actions)
  end

  def available_actions
    ::Automations::Register.actions.map(&:all).flatten
  end

  def all_conditions
    all_of(available_conditions, conditions)
  end

  def available_conditions
    self.class.available_conditions
  end

  def conditions
    @conditions ||= available_conditions.filter_map do |condition_class|
      condition_class.getter(self)
    end
  end

  def conditions=(new_conditions)
    conditions_will_change!
    @conditions = new_conditions
  end

  def conditions_fulfilled?(work_package, user)
    conditions.all? { |c| c.fulfilled_by?(work_package, user) }
  end

  def self.available_conditions
    ::Automations::Register.conditions
  end

  private

  def ensure_manual_trigger
    return unless triggers.reject(&:marked_for_destruction?).empty?

    triggers.build(type: "Automations::Triggers::Manual", options: { button_label: name })
  end

  def all_of(availables, actual)
    availables.map do |available|
      existing = actual.detect { |a| a.key == available.key }

      existing || available.new
    end
  end

  def persist_conditions
    available_conditions.map do |condition_class|
      condition = conditions.detect { |c| c.instance_of?(condition_class) }

      condition_class.setter(self, condition)
    end
  end

  def must_have_at_least_one_trigger
    errors.add(:triggers, :blank) if triggers.reject(&:marked_for_destruction?).empty?
  end

  def must_not_have_more_than_one_manual_trigger
    manual_triggers = triggers.reject(&:marked_for_destruction?).count { |trigger| trigger.type == "Automations::Triggers::Manual" }
    errors.add(:triggers, :invalid) if manual_triggers > 1
  end
end
