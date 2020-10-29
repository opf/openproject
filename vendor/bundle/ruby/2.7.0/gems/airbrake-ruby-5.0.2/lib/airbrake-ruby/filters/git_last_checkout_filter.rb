require 'date'

module Airbrake
  module Filters
    # Attaches git checkout info to `context`. The info includes:
    #   * username
    #   * email
    #   * revision
    #   * time
    #
    # This information is used to track deploys automatically.
    #
    # @api private
    # @since v2.12.0
    class GitLastCheckoutFilter
      # @return [Integer]
      attr_reader :weight

      # @return [Integer] least possible amount of columns in git's `logs/HEAD`
      #   file (checkout information is omitted)
      MIN_HEAD_COLS = 6

      include Loggable

      # @param [String] root_directory
      def initialize(root_directory)
        @git_path = File.join(root_directory, '.git')
        @weight = 116
        @last_checkout = nil
        @deploy_username = ENV['AIRBRAKE_DEPLOY_USERNAME']
      end

      # @macro call_filter
      def call(notice)
        return if notice[:context].key?(:lastCheckout)

        if @last_checkout
          notice[:context][:lastCheckout] = @last_checkout
          return
        end

        return unless File.exist?(@git_path)
        return unless (checkout = last_checkout)

        notice[:context][:lastCheckout] = checkout
      end

      private

      def last_checkout
        return unless (line = last_checkout_line)

        parts = line.chomp.split("\t").first.split(' ')
        if parts.size < MIN_HEAD_COLS
          logger.error(
            "#{LOG_LABEL} Airbrake::#{self.class.name}: can't parse line: #{line}",
          )
          return
        end

        author = parts[2..-4]
        @last_checkout = {
          username: @deploy_username || author[0..1].join(' '),
          email: parts[-3][1..-2],
          revision: parts[1],
          time: timestamp(parts[-2].to_i),
        }
      end

      def last_checkout_line
        head_path = File.join(@git_path, 'logs', 'HEAD')
        return unless File.exist?(head_path)

        last_line = nil
        IO.foreach(head_path) do |line|
          last_line = line if checkout_line?(line)
        end
        last_line
      end

      def checkout_line?(line)
        line.include?("\tclone:") ||
          line.include?("\tpull:") ||
          line.include?("\tcheckout:")
      end

      def timestamp(utime)
        Time.at(utime).to_datetime.rfc3339
      end
    end
  end
end
