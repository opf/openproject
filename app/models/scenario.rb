class Scenario < ActiveRecord::Base
  unloadable

  self.table_name = 'scenarios'

  include TimestampsCompatibility
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :project

  has_many :alternate_dates, :class_name  => 'AlternateDate',
                             :foreign_key => 'scenario_id',
                             :dependent   => :delete_all

  validates_presence_of :name, :project

  validates_length_of :name, :maximum => 255, :unless => lambda { |e| e.name.blank? }
end
