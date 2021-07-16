class ErrorsController < ::ActionController::Base
  include ErrorsHelper
  include OpenProjectErrorHelper
  include Accounts::CurrentUser

  def not_found
    render_404
  end

  def unacceptable
    render file: "#{Rails.root}/public/422.html",
           status: :unacceptable,
           layout: false
  end

  def internal_error
    render_500
  end

  private

  def use_layout
    'only_logo'
  end
end
