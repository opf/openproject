module Components
  ##
  # A language switch and text area for updating a localized text setting.
  class OnOffStatusCell < ::RailsCell
    options :on_text
    options :on_description
    options :off_text
    options :off_description

    options :is_on

    def enabled?
      !!model[:is_on]
    end
  end
end
