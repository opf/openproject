class LicensesController < ApplicationController
  layout 'admin'

  before_action :require_admin

  def edit
    @license = License.current || License.new
  end

  def update
    @license = License.current || License.new
    @license.encoded_license = params[:license][:encoded_license]

    if @license.save
      flash[:notice] = t(:notice_successful_update)
      redirect_to action: 'edit'
    else
      render action: 'edit'
    end

  end

  private

  def default_breadcrumb
    t(:label_license)
  end

end
