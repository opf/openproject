module OpenProject
  module Meeting
    module DefaultData
      module_function

      def load!
        add_permissions! (member_role || raise('Member role not found')), member_permissions
        add_permissions! (reader_role || raise('Reader role not found')), reader_permissions
      end

      def add_permissions!(role, permissions)
        role.add_permission! *permissions
      end

      def member_role
        Role.find_by name: I18n.t(:default_role_member)
      end

      def member_permissions
        [
          :create_meetings,
          :edit_meetings,
          :delete_meetings,
          :view_meetings,
          :create_meeting_agendas,
          :close_meeting_agendas,
          :send_meeting_agendas_notification,
          :send_meeting_agendas_icalendar,
          :create_meeting_minutes,
          :send_meeting_minutes_notification
        ]
      end

      def reader_role
        Role.find_by name: I18n.t(:default_role_reader)
      end

      def reader_permissions
        [:view_meetings]
      end
    end
  end
end
