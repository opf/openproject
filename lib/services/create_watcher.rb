class Services::CreateWatcher
  def initialize(work_package, user)
    @work_package = work_package
    @user = user

    @watcher = Watcher.new(user: user, watchable: work_package)
  end

  def run(success = -> {}, failure = -> {})
    if @work_package.watcher_users.include?(@user)
      success.(created: false)
    else
      if @watcher.valid?
        @work_package.watchers << @watcher
        success.(created: true)
      else
        error.(@watcher)
      end
    end
  end
end
