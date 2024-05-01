require 'webrick'
require 'httpx'

RSpec.describe 'HTTPX' do
  describe 'persistent connections' do
    it 'does not hang forever when used to request HTTP 1.1 server' do
      server = WEBrick::HTTPServer.new(:Port => 8543)
      server.mount_proc '/' do |req, res|
        res.body = 'Response Body'
      end

      Thread.new { server.start }
      session = HTTPX .plugin(:persistent).with(timeout: {keep_alive_timeout: 2})
      number_of_requests_made = 0
      begin
        Timeout.timeout(10) do
          session.post("http://localhost:8543")
          number_of_requests_made += 1
          sleep 4
          session.post("http://localhost:8543")
          number_of_requests_made += 1
        end
      ensure
        expect(number_of_requests_made).to eq(2)
        server.shutdown
      end
    end
  end
end
