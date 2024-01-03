module OpenProject
  module Common
    # @logical_path OpenProject/Common
    class SubmenuComponentPreview < Lookbook::Preview
      def default
        # Meant to be rendered inside the left-handed sidebar
        render OpenProject::Common::SubmenuComponent.new(
          sidebar_menu_items: [
            {
              header: nil,
              children: [
                { title: I18n.t('members.menu.all'), href: '' },
                { title: I18n.t('members.menu.locked'), href: '' },
                { title: I18n.t('members.menu.invited'), href: '' }
              ]
            },
            {
              header: I18n.t('members.menu.project_roles'),
              children: [{ title: 'ROLE X', href: '' }]
            },
            {
              header: I18n.t('members.menu.groups'),
              children: [{ title: 'GROUP X', href: '' }]
            }
          ]
        )
      end
    end
  end
end
