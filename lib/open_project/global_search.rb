module OpenProject
  module GlobalSearch
    def self.tab_name(tab)
      I18n.t("global_search.overwritten_tabs.#{tab}",
             default: I18n.t("label_#{tab.singularize}_plural",
                             default: tab.to_s.humanize))
    end
  end
end
