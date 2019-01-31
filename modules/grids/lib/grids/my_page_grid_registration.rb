module Grids
  class MyPageGridRegistration < ::Grids::Configuration::Registration
    grid_class 'Grids::MyPage'
    to_scope :my_page_path

    widgets 'work_packages_assigned',
            'work_packages_accountable',
            'work_packages_watched',
            'work_packages_created',
            'work_packages_calendar',
            'time_entries_current_user',
            'documents',
            'news'

    class << self
      def from_scope(scope)
        if scope == url_helpers.my_page_path
          { class: Grids::MyPage }
        end
      end

      def visible(user = User.current)
        super
          .where(user_id: user.id)
      end
    end
  end
end
