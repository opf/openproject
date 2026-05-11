# frozen_string_literal: true

module Automations
  class RowComponent < ::RowComponent
    def automation
      row
    end

    def name
      link_to automation.name, edit_automation_path(automation)
    end

    def triggers
      automation.triggers.map do |trigger|
        case trigger
        when Automations::Triggers::Manual
          I18n.t("automations.triggers.manual.label")
        else
          trigger.type.demodulize
        end
      end.join(", ")
    end

    def conditions
      automation.conditions.map(&:human_name).join(", ")
    end

    def actions
      automation.actions.map(&:human_name).join(", ")
    end

    def sort
      helpers.reorder_links("automation", { action: "update", id: automation }, method: :put)
    end

    def button_links
      [
        edit_link,
        delete_link
      ]
    end

    def edit_link
      link_to(
        helpers.op_icon("icon icon-edit"),
        helpers.edit_automation_path(automation),
        title: t(:button_edit)
      )
    end

    def delete_link
      link_to(
        helpers.op_icon("icon icon-delete"),
        helpers.automation_path(automation),
        data: {
          turbo_method: :delete,
          turbo_confirm: I18n.t(:text_are_you_sure)
        },
        title: t(:button_delete)
      )
    end
  end
end
