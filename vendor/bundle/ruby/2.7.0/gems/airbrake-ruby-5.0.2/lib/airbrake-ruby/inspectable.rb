module Airbrake
  # Inspectable provides custom inspect methods that reduce clutter printed in
  # REPLs for notifier objects. These custom methods display only essential
  # information such as project id/key and filters.
  #
  # @since v3.2.6
  # @api private
  module Inspectable
    # @return [String] inspect output template
    INSPECT_TEMPLATE =
      "#<%<classname>s:0x%<id>s project_id=\"%<project_id>s\" " \
      "project_key=\"%<project_key>s\" " \
      "host=\"%<host>s\" filter_chain=%<filter_chain>s>".freeze

    # @return [String] customized inspect to lessen the amount of clutter
    def inspect
      format(
        INSPECT_TEMPLATE,
        classname: self.class.name,
        id: (object_id << 1).to_s(16).rjust(16, '0'),
        project_id: @config.project_id,
        project_key: @config.project_key,
        host: @config.host,
        filter_chain: @filter_chain.inspect,
      )
    end

    # @return [String] {#inspect} for PrettyPrint
    def pretty_print(q)
      q.text("#<#{self.class}:0x#{(object_id << 1).to_s(16).rjust(16, '0')} ")
      q.text(
        "project_id=\"#{@config.project_id}\" project_key=\"#{@config.project_key}\" " \
        "host=\"#{@config.host}\" filter_chain=",
      )
      q.pp(@filter_chain)
      q.text('>')
    end
  end
end
