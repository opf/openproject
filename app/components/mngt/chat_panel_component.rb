# frozen_string_literal: true

class Mngt::ChatPanelComponent < ApplicationComponent
  def render?
    User.current.logged? && Mngt::Stream.configured?
  end

  def token_url
    mngt_stream_token_path
  end

  def users_url
    mngt_stream_users_path
  end

  def group_members_url
    mngt_stream_group_members_path
  end
end
