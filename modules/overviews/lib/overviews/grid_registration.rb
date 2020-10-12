module Overviews
  class GridRegistration < ::Grids::Configuration::InProjectBaseRegistration
    grid_class 'Grids::Overview'
    to_scope :project_overview_path

    view_permission :view_project
    edit_permission :manage_overview
    in_project_scope_path nil

    defaults -> {
      {
        row_count: 3,
        column_count: 2,
        widgets: [
          {
            identifier: 'project_description',
            start_row: 1,
            end_row: 2,
            start_column: 1,
            end_column: 2,
            options: {
              name: I18n.t('js.grid.widgets.project_description.title')
            }
          },
          {
            identifier: 'project_status',
            start_row: 1,
            end_row: 2,
            start_column: 2,
            end_column: 3,
            options: {
              name: I18n.t('js.grid.widgets.project_status.title')
            }
          },
          {
            identifier: 'project_details',
            start_row: 2,
            end_row: 3,
            start_column: 1,
            end_column: 2,
            options: {
              name: I18n.t('js.grid.widgets.project_details.title')
            }
          },
          {
            identifier: 'work_packages_overview',
            start_row: 3,
            end_row: 4,
            start_column: 1,
            end_column: 3,
            options: {
              name: I18n.t('js.grid.widgets.work_packages_overview.title')
            }
          },
          {
            identifier: 'members',
            start_row: 2,
            end_row: 3,
            start_column: 2,
            end_column: 3,
            options: {
              name: I18n.t('js.grid.widgets.members.title')
            }
          }
        ]
      }
    }

    validations :create, ->(*_args) {
      if Grids::Overview.where(project_id: model.project_id).exists?
        errors.add(:scope, :taken)
      end
    }

    validations :create, ->(*_args) {
      next if user.allowed_to?(:manage_overview, model.project)

      defaults = Overviews::GridRegistration.defaults

      %i[row_count column_count].each do |count|
        if model.send(count) != defaults[count]
          errors.add(count, :unchangeable)
        end
      end

      model.widgets.each do |widget|
        widget_default = defaults[:widgets].detect { |w| w[:identifier] == widget.identifier }

        if widget.attributes.except("options") != widget_default.attributes.except("options") ||
           widget.attributes["options"].stringify_keys != widget_default.attributes["options"].stringify_keys
          errors.add(:widgets, :unchangeable)
        end
      end
    }

    class << self
      def writable?(grid, user)
        # New records are allowed to be saved by everybody. Other parts
        # of the application prevent a user from saving arbitrary pages.
        # Only the default config is allowed and only one page per project is allowed.
        # That way, a new page can be created on the fly without the user noticing.
        super || grid.new_record?
      end
    end
  end
end
