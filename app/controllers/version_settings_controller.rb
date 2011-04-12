class VersionSettingsController < RbApplicationController
  unloadable

  def edit
    @version = Version.find(params[:id])
  end

  private

  def authorize
    super "versions", "edit" #everyone with the right to edit versions has the right to edit version settings
  end
end