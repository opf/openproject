module SWD
  module Debugger
    class RequestFilter
      # Callback called in HTTPClient (before sending a request)
      # request:: HTTP::Message
      def filter_request(request)
        started = "======= [SWD] HTTP REQUEST STARTED ======="
        SWD.logger.info [started, request.dump].join("\n")
      end

      # Callback called in HTTPClient (after received a response)
      # request::  HTTP::Message
      # response:: HTTP::Message
      def filter_response(request, response)
        finished = "======= [SWD] HTTP REQUEST FINISHED ======="
        SWD.logger.info ['-' * 50, response.dump, finished].join("\n")
      end
    end
  end
end