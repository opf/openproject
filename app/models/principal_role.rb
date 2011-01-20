class PrincipalRole < ActiveRecord::Base
  belongs_to :principal
  belongs_to :role

  def validate
    add_error_can_not_be_assigned unless self.role.assignable_to?(self.principal)
  end

  private

  def add_error_can_not_be_assigned
    self.errors.add_to_base l(:error_can_not_be_assigned)
  end
end