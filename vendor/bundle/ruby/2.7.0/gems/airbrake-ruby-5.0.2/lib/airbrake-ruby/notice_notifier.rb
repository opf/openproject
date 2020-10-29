module Airbrake
  # NoticeNotifier is reponsible for sending notices to Airbrake. It supports
  # synchronous and asynchronous delivery.
  #
  # @see Airbrake::Config The list of options
  # @since v1.0.0
  # @api public
  class NoticeNotifier
    # @return [Array<Class>] filters to be executed first
    DEFAULT_FILTERS = [
      Airbrake::Filters::SystemExitFilter,
      Airbrake::Filters::GemRootFilter,

      # Optional filters (must be included by users):
      # Airbrake::Filters::ThreadFilter
    ].freeze

    include Inspectable
    include Loggable

    def initialize
      @config = Airbrake::Config.instance
      @context = {}
      @filter_chain = FilterChain.new
      @async_sender = AsyncSender.new
      @sync_sender = SyncSender.new

      DEFAULT_FILTERS.each { |filter| add_filter(filter.new) }

      add_filter(Airbrake::Filters::ContextFilter.new(@context))
      add_filter(Airbrake::Filters::ExceptionAttributesFilter.new)
    end

    # @see Airbrake.notify
    def notify(exception, params = {}, &block)
      send_notice(exception, params, default_sender, &block)
    end

    # @see Airbrake.notify_sync
    def notify_sync(exception, params = {}, &block)
      send_notice(exception, params, @sync_sender, &block).value
    end

    # @see Airbrake.add_filte
    def add_filter(filter = nil, &block)
      @filter_chain.add_filter(block_given? ? block : filter)
    end

    # @see Airbrake.delete_filter
    def delete_filter(filter_class)
      @filter_chain.delete_filter(filter_class)
    end

    # @see Airbrake.build_notice
    def build_notice(exception, params = {})
      if @async_sender.closed?
        raise Airbrake::Error,
              "Airbrake is closed; can't build exception: " \
              "#{exception.class}: #{exception}"
      end

      if exception.is_a?(Airbrake::Notice)
        exception[:params].merge!(params)
        exception
      else
        Notice.new(convert_to_exception(exception), params.dup)
      end
    end

    # @see Airbrake.close
    def close
      @async_sender.close
    end

    # @see Airbrake.configured?
    def configured?
      @config.valid?
    end

    # @see Airbrake.merge_context
    def merge_context(context)
      @context.merge!(context)
    end

    # @return [Boolean]
    # @since v4.14.0
    def has_filter?(filter_class) # rubocop:disable Naming/PredicateName
      @filter_chain.includes?(filter_class)
    end

    private

    def convert_to_exception(ex)
      if ex.is_a?(Exception) || Backtrace.java_exception?(ex)
        # Manually created exceptions don't have backtraces, so we create a fake
        # one, whose first frame points to the place where Airbrake was called
        # (normally via `notify`).
        ex.set_backtrace(clean_backtrace) unless ex.backtrace
        return ex
      end

      e = RuntimeError.new(ex.to_s)
      e.set_backtrace(clean_backtrace)
      e
    end

    def send_notice(exception, params, sender)
      promise = @config.check_configuration
      return promise if promise.rejected?

      notice = build_notice(exception, params)
      yield notice if block_given?
      @filter_chain.refine(notice)

      promise = Airbrake::Promise.new
      return promise.reject("#{notice} was marked as ignored") if notice.ignored?

      sender.send(notice, promise)
    end

    def default_sender
      return @async_sender if @async_sender.has_workers?

      logger.warn(
        "#{LOG_LABEL} falling back to sync delivery because there are no " \
        "running async workers",
      )
      @sync_sender
    end

    def clean_backtrace
      caller_copy = Kernel.caller
      clean_bt = caller_copy.drop_while { |frame| frame.include?('/lib/airbrake') }

      # If true, then it's likely an internal library error. In this case return
      # at least some backtrace to simplify debugging.
      return caller_copy if clean_bt.empty?

      clean_bt
    end
  end
end
