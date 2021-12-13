module Views
  class CalendarStrategy < ::BaseContract
    validate :manageable

    private

    def manageable
      return if model.query.blank?

      errors.add(:base, :error_unauthorized) unless query_permissions?
    end

    def query_permissions?
      user_allowed_on_query?(:view_calendar)
    end

    def user_allowed_on_query?(permission)
      user.allowed_to?(permission, model.query.project, global: model.query.project.nil?)
    end
  end
end
