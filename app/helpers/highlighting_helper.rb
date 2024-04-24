module HighlightingHelper
  def highlight_css_version_tag(max_updated_at = highlight_css_updated_at)
    OpenProject::Cache::CacheKey.expand max_updated_at
  end

  def highlight_css_updated_at
    ApplicationRecord.most_recently_changed Status, IssuePriority, Type
  end
end
