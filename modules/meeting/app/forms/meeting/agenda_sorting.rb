# frozen_string_literal: true

class Meeting::AgendaSorting < ApplicationForm
  form do |form|
    form.radio_button_group(name: :agenda_sorting_mode, label: I18n.t("meeting.agenda_sorting.title")) do |group|
      %w[manual vote_based].each do |mode|
        group.radio_button(
          value: mode,
          checked: model.agenda_sorting_mode == mode,
          label: I18n.t("meeting.agenda_sorting.#{mode}"),
          caption: I18n.t("meeting.agenda_sorting.#{mode}_description")
        )
      end
    end
  end
end
