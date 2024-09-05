class Admin::Settings::ProgressTrackingSettingsForm < ApplicationForm
  attr_reader :i18n_scope

  def initialize
    super
    @i18n_scope = "admin.settings.progress_tracking_settings_form"
  end

  form do |form_element|
    form_element.radio_button_group(
      name: "settings[work_package_done_ratio]",
      label: I18n.t("#{i18n_scope}.progress_calculation_section.group_label")
    ) do |group|
      group.radio_button(label: I18n.t(:label_work_based),
                         value: WorkPackage::DONE_RATIO_FIELD_OPTION,
                         checked: WorkPackage.use_field_for_done_ratio?,
                         caption: I18n.t("#{i18n_scope}.progress_calculation_section.work_based_caption"))
      group.radio_button(label: I18n.t(:label_status_based),
                         value: WorkPackage::DONE_RATIO_STATUS_OPTION,
                         checked: WorkPackage.use_status_for_done_ratio?,
                         caption: I18n.t("#{i18n_scope}.progress_calculation_section.status_based_caption"))
    end

    form_element.submit(scheme: :primary,
                        name: :submit,
                        label: I18n.t(:button_save))
  end
end
