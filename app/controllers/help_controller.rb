class HelpController < ApplicationController
  def wiki_syntax
    render :layout => false
  end

  def wiki_syntax_detailed
    render :layout => false
  end
end
