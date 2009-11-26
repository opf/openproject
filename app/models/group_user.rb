class GroupUser < ActiveRecord::Base
  set_table_name 'groups_users'
  
  belongs_to :user
  belongs_to :group
  
  MEMBERSHIP_TYPES = %w(default controller)
  DEFAULT_MEMBERSHIP_TYPE = :default
  
  validates_inclusion_of :membership_type, :in => MEMBERSHIP_TYPES
  validates_presence_of :user_id, :group_id
  
  def after_initialize
    membership_type ||= :default
  end
end
