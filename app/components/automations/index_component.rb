# frozen_string_literal: true

module Automations
  class IndexComponent < ::TableComponent
    columns :name, :triggers, :conditions, :actions, :sort

    def headers
      [
        ["name", { caption: Automation.human_attribute_name(:name) }],
        ["triggers", { caption: I18n.t("automations.triggers.name") }],
        ["conditions", { caption: I18n.t("automations.conditions") }],
        ["actions", { caption: I18n.t("automations.actions.name") }],
        ["sort", { caption: I18n.t(:label_sort) }]
      ]
    end

    def sortable?
      false
    end

    def inline_create_link
      link_to new_automation_path,
              aria: { label: t("automations.new") },
              class: "wp-inline-create--add-link",
              title: t("automations.new") do
        helpers.op_icon("icon icon-add")
      end
    end
  end
end
