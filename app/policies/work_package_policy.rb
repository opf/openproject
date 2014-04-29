class WorkPackagePolicy
  attr_reader :user, :work_package

  def initialize(user, work_package)
    @user = user
    @work_package = work_package
  end

  def index?
  end

  # if project is public
  # ...
  def show?
    user.admin? ||
    work_package.project.is_public?
  end

  def create?
  end

  def update?
  end

  def delete?
  end
end
