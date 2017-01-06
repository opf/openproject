class LicensesController < ApplicationController
  layout 'admin'
  menu_item :license

  before_action :require_admin

  def show
    @license = License.current || License.new
  end

  def create
    @license = License.new
    @license.encoded_license = params[:license][:encoded_license]

    if @license.save
      flash[:notice] = t(:notice_successful_update)
    end

    render action: :show
  end

  def destroy
    license = License.find(params[:id])
    if license
      license.destroy
      flash[:notice] = t(:notice_successful_delete)
      redirect_to action :show
    else
      render_404
    end
  end

  private

  def default_breadcrumb
    t(:label_license)
  end

end
