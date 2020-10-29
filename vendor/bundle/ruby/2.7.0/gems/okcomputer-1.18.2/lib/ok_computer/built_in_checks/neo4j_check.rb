module OkComputer
  class Neo4jCheck < Check
    def check
      begin
        #Checks the connection for a 200
        connected = Neo4j::Session.current.connection.head.success?
        url = Neo4j::Session.current.connection.url_prefix.to_s
        mark_message "Connected to neo4j on #{url}" if connected
      rescue Faraday::ConnectionFailed => e
        mark_failure
        mark_message "Error: #{e.message}"
      end
    end
  end
end
