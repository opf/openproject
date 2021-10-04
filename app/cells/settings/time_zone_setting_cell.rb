module Settings
  ##
  # A text field to enter numeric values.
  class TimeZoneSettingCell < ::RailsCell
    include ActionView::Helpers::FormOptionsHelper
    include SettingsHelper

    options :form, :title
    options container_class: "-wide"
    options include_blank: true

    # name of setting and tag
    def name
      model
    end

    def render_select
      if form.nil?
        render_setting_select
      else
        render_form_select
      end
    end

    def render_form_select
      form.select(
        name,
        time_zone_entries,
        include_blank: include_blank,
        container_class: container_class,
        title: title
      )
    end

    def render_setting_select
      setting_select(
        name,
        time_zone_entries,
        include_blank: include_blank,
        container_class: container_class,
        title: title
      )
    end

    def time_zones
      ActiveSupport::TimeZone.all
    end

    ##
    # Returns time zone (label, value) tuples to be used for a select field.
    # As we only store tzinfo compatible data we only provide options, for which the
    # values can later on be retrieved unambiguously. This is not always the case
    # for values in ActiveSupport::TimeZone since multiple AS zones map to single tzinfo zones.
    def time_zone_entries
      time_zones
        .group_by { |tz| tz.tzinfo.name }
        .values
        .map do |zones|
        tz = namesake_time_zone(zones)

        [tz.to_s, tz.tzinfo.canonical_identifier]
      end
    end

    # If there are multiple AS::TimeZones for a single TZInfo::Timezone, we
    # one return the one that is the namesake.
    def namesake_time_zone(time_zones)
      if time_zones.length == 1
        time_zones.first
      else
        time_zones.detect { |tz| tz.tzinfo.name.include?(tz.name.gsub(' ', '_')) }
      end
    end
  end
end
