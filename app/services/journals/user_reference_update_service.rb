module Journals
  class UserReferenceUpdateService
    attr_accessor :original_user

    def initialize(original_user)
      self.original_user = original_user
    end

    def call(substitute_user)
      journal_classes.each do |klass|
        foreign_keys.each do |foreign_key|
          if klass.column_names.include? foreign_key
            klass
              .where(foreign_key => original_user.id)
              .update_all(foreign_key => substitute_user.id)
          end
        end
      end

      ServiceResult.new success: true
    end

    private

    def journal_classes
      [Journal] + Journal::BaseJournal.subclasses
    end

    def foreign_keys
      %w[author_id user_id assigned_to_id responsible_id]
    end
  end
end
