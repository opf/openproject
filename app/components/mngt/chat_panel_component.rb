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

  def is_admin?
    User.current.admin?
  end

  def can_see_all?
    Mngt::Companies.can_see_all_by_slug?(company_slug)
  end

  def company_slug
    Mngt::UserProfile.where(user: User.current).pick(:company_slug) ||
      Mngt::Companies.slug_for(User.current.mail) || "unknown"
  end

  def companies_map_json
    Mngt::Companies.slug_to_name.to_json
  end
end
