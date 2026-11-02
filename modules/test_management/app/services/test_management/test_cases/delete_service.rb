# frozen_string_literal: true

module TestManagement
  module TestCases
    # Soft-delete so global numeric IDs are never reused.
    class DeleteService < ::BaseServices::Delete
      def destroy(object)
        object.soft_delete!
        object.events.create!(action: "deleted", user_id: user.id)
        true
      end
    end
  end
end
