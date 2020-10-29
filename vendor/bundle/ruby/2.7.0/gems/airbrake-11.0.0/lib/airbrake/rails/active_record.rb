# frozen_string_literal: true

module Airbrake
  module Rails
    # Rails <4.2 has a bug with regard to swallowing exceptions in the
    # +after_commit+ and the +after_rollback+ hooks: it doesn't bubble up
    # exceptions from there.
    #
    # This module makes it possible to report exceptions occurring there.
    #
    # @see https://github.com/rails/rails/pull/14488 Detailed description of the
    #   bug and the fix
    # @see https://goo.gl/348lor Rails 4.2+ implementation (fixed)
    # @see https://goo.gl/ddFNg7 Rails <4.2 implementation (bugged)
    module ActiveRecord
      # Patches default +run_callbacks+ with our version, which is capable of
      # notifying about exceptions.
      #
      # rubocop:disable Lint/RescueException
      def run_callbacks(kind, *args, &block)
        # Let the post process handle the exception if it's not a bugged hook.
        return super unless %i[commit rollback].include?(kind)

        # Handle the exception ourselves. The 'ex' exception won't be
        # propagated, therefore we must notify it here.
        begin
          super
        rescue Exception => ex
          Airbrake.notify(ex)
          raise ex
        end
      end
      # rubocop:enable Lint/RescueException
    end
  end
end
