module OpenProject
  module Reminders
    class DueIssuesReminder
      attr_reader :due_date_in_days, :due_date, :project, :type, :user_ids, :notify_count

      def initialize(days: 7, project_id: nil, type_id: nil, user_ids: [])
        @due_date_in_days = days.to_i
        @due_date = due_date_in_days.days.from_now.to_date
        @project = Project.find_by(id: project_id.to_i) if project_id
        @type = ::Type.find_by(id: type_id.to_i) if type_id
        @user_ids = Array(user_ids).map(&:to_i).reject(&:zero?)
        @notify_count = 0
      end

      ##
      # Send reminder mails for the given instantiation
      def remind_users
        assigned_principals.each do |principal, issues|
          case principal
          when Group
            principal.users.each { |user| send_reminder_mail!(user, issues, principal) }
          when User
            send_reminder_mail!(principal, issues)
          else
            Rails.logger.info { "Skipping reminder mail for undeliverable principal #{principal.class.name} #{principal.id} " }
          end
        end
      end

      ##
      # Deliver the reminder mail now for the given user
      # assuming it is active
      def send_reminder_mail!(user, issues, group = nil)
        if user&.active?
          UserMailer.reminder_mail(user, issues, due_date_in_days, group).deliver_now
          @notify_count += 1
        end
      rescue StandardError => e
        Rails.logger.error { "Failed to deliver reminder_mail to user##{user.id}: #{e.message}" }
      end

      def assigned_principals
        scope = WorkPackage
          .includes(:status, :assigned_to, :project, :type)
          .where("#{Status.table_name}.is_closed = false AND #{WorkPackage.table_name}.due_date <= ?", due_date)
          .where("#{WorkPackage.table_name}.assigned_to_id IS NOT NULL")
          .where("#{Project.table_name}.active = #{true}")

        if user_ids.any?
          scope = scope.where("#{WorkPackage.table_name}.assigned_to_id IN (?)", user_ids)
        end

        if project
          scope = scope.where("#{WorkPackage.table_name}.project_id = #{project.id}")
        end

        if type
          scope = scope.where("#{WorkPackage.table_name}.type_id = #{type.id}")
        end

        scope
          .references(:projects, :statuses, :work_packages)
          .group_by(&:assigned_to)
      end
    end
  end
end
