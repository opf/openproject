module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module NestedSet #:nodoc:
      module Model
        module Transactable
          class OpenTransactionsIsNotZero < ActiveRecord::StatementInvalid
          end

          class DeadlockDetected < ActiveRecord::StatementInvalid
          end

          protected
          def in_tenacious_transaction(&block)
            retry_count = 0
            begin
              transaction(&block)
            rescue CollectiveIdea::Acts::NestedSet::Move::ImpossibleMove
              raise
            rescue ActiveRecord::StatementInvalid => error
              raise OpenTransactionsIsNotZero.new(error.message) unless self.class.connection.open_transactions.zero?
              raise unless error.message =~ /[Dd]eadlock|Lock wait timeout exceeded/
              raise DeadlockDetected.new(error.message) unless retry_count < 10
              retry_count += 1
              logger.info "Deadlock detected on retry #{retry_count}, restarting transaction"
              sleep(rand(retry_count)*0.1) # Aloha protocol
              retry
            end
          end

        end
      end
    end
  end
end
