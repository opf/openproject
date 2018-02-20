module Settings
  ##
  # A text field to enter numeric values.
  class TimeZoneSettingCell < ::RailsCell
    include ActionView::Helpers::FormOptionsHelper
    include SettingsHelper

    options :form, :title
    options container_class: "-wide"
    options include_blank: true

    def name # name of setting and tag
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
    def time_zone_entries
      time_zones.map { |tz| [tz.to_s, tz.name ] }
    end
  end
end
