class FilterSettingsHelper
  class << self
    def group_by_setting(query)
      I18n.t("field_#{query.group_by.to_s.gsub(/\_id$/, "")}") if query.group_by
    end
    
    def filter_settings(query)
      filters = query.available_filters
      filters.sort{|a,b| a[1][:order] <=> b[1][:order]}.collect do |field, options|
        if query.has_filter? field
          o = query.filters[field.to_s][:operator]
          ((options[:name] || I18n.t(("field_#{field.to_s.gsub(/\_id$/, "")}"))) + " " +
            I18n.t(Query.operators[o], :default => o.to_s) + " " +
            query.values_for(field).collect do |v|
              if options[:values]
                options[:values].detect do |o| 
                  o[1] == v
                end
              else
                [v]
              end
            end.compact.collect(&:first).join(" #{I18n.t(:sentence_separator_or)} "))
        end
      end.compact
    end
  end
end