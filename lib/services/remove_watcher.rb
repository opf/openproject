class Services::RemoveWatcher
  def initialize(work_package, user)
    @work_package = work_package
    @user = user
  end

  def run(success = -> {}, failure = -> {})
    if @work_package.watcher_users.include?(@user)
      @work_package.watcher_users.delete(@user)
      success.call
    else
      failure.call
    end
  end
end
