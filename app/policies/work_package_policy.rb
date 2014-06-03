class WorkPackagePolicy < ApplicationPolicy
  def index?
  end

  # if project is public
  # ...
  def show?
    @user.admin? ||
    @record.project.is_public?
  end

  def create?
  end

  def update?
  end

  def delete?
  end
end
