# frozen_string_literal: true

class Mngt::ChatPanelComponent < ApplicationComponent
  def render?
    User.current.logged? && Mngt::Stream.configured?
  end

  def token_url
    mngt_stream_token_path
  end
end
