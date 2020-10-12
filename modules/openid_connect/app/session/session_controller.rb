class SessionController < ActionController::Base
  def logout_warning
    url = signin_url back_url: params[:back_url]

    render 'logout_warning', locals: { message: link_i18n(:logout_warning, url) }
  end

  private

  ##
  # Finds any words enclosed in brackets (like links in Markdown) and
  # turns them into a link with the given URL.
  def link_i18n(i18n_key, url)
    text = translate i18n_key
    html = text.gsub /\[([^\[\]]+)\]/, "<a href=\"#{url}\">\\1</a>"

    html.html_safe
  end
end
