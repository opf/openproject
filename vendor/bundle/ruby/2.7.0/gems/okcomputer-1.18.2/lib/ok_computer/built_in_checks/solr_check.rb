module OkComputer
  # This class performs a health check on Solr instance using the
  # admin/ping handler.
  class SolrCheck < HttpCheck
    attr_reader :host

    # Public: Initialize a new Solr check.
    #
    # host - The hostname of Solr
    # request_timeout - How long to wait to connect before timing out. Defaults to 5 seconds.
    def initialize(host, request_timeout = 5)
      @host = URI(host)
      super("#{host}/admin/ping", request_timeout)
    end

    # Public: Return the status of Solr
    def check
      if ping?
        mark_message "Solr ping reported success"
      else
        mark_failure
        mark_message "Solr ping reported failure"
      end
    rescue => e
      mark_failure
      mark_message "Error: '#{e}'"
    end

    # Public: Returns true if Solr's ping returned OK, otherwise false
    def ping?
      response = perform_request
      !!(response =~ Regexp.union(%r(<str name="status">OK</str>), %r("status":"OK")))
    end
  end
end
