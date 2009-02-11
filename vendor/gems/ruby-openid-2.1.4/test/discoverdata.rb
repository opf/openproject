
require 'uri'
require 'openid/yadis/constants'
require 'openid/yadis/discovery'
require 'openid/extras'
require 'openid/util'

module OpenID

  module DiscoverData

    include TestDataMixin
    include Util

    TESTLIST = [
                # success,  input_name,          id_name,            result_name
                [true,  "equiv",             "equiv",            "xrds"],
                [true,  "header",            "header",           "xrds"],
                [true,  "lowercase_header",  "lowercase_header", "xrds"],
                [true,  "xrds",              "xrds",             "xrds"],
                [true,  "xrds_ctparam",      "xrds_ctparam",     "xrds_ctparam"],
                [true,  "xrds_ctcase",       "xrds_ctcase",      "xrds_ctcase"],
                [false, "xrds_html",         "xrds_html",        "xrds_html"],
                [true,  "redir_equiv",       "equiv",            "xrds"],
                [true,  "redir_header",      "header",           "xrds"],
                [true,  "redir_xrds",        "xrds",             "xrds"],
                [false, "redir_xrds_html",   "xrds_html",        "xrds_html"],
                [true,  "redir_redir_equiv", "equiv",            "xrds"],
                [false, "404_server_response", nil,             nil],
                [false, "404_with_header",     nil,             nil],
                [false, "404_with_meta",       nil,             nil],
                [false, "201_server_response", nil,             nil],
                [false, "500_server_response", nil,             nil],
             ]

    @@example_xrds_file = 'example-xrds.xml'
    @@default_test_file = 'test1-discover.txt'
    @@discover_tests = {}

    def readTests(filename)
      data = read_data_file(filename, false)
      tests = {}
      data.split("\f\n", -1).each { |case_|
        name, content = case_.split("\n", 2)
        tests[name] = content
      }

      return tests
    end

    def getData(filename, name)
      if !@@discover_tests.member?(filename)
        @@discover_tests[filename] = readTests(filename)
      end

      file_tests = @@discover_tests[filename]
      return file_tests[name]
    end

    def fillTemplate(test_name, template, base_url, example_xrds)
      mapping = [
                 ['URL_BASE/', base_url],
                 ['<XRDS Content>', example_xrds],
                 ['YADIS_HEADER', Yadis::YADIS_HEADER_NAME],
                 ['NAME', test_name],
                ]

      mapping.each { |k, v|
        template = template.gsub(/#{k}/, v)
      }

      return template
    end

    def generateSample(test_name, base_url,
                       example_xrds=nil,
                       filename=@@default_test_file)
      if example_xrds.nil?
        example_xrds = read_data_file(@@example_xrds_file, false)
      end

      begin
        template = getData(filename, test_name)
      rescue Errno::ENOENT
        raise ArgumentError(filename)
      end

      return fillTemplate(test_name, template, base_url, example_xrds)
    end

    def generateResult(base_url, input_name, id_name, result_name, success)
      uri = URI::parse(base_url)

      input_url = (uri + input_name).to_s

      # If the name is None then we expect the protocol to fail, which
      # we represent by None
      if id_name.nil?
        Util.assert(result_name.nil?)
        return input_url, DiscoveryFailure
      end

      result = generateSample(result_name, base_url)
      headers, content = result.split("\n\n", 2)
      header_lines = headers.split("\n")

      ctype = nil
      header_lines.each { |header_line|
        if header_line.starts_with?('Content-Type:')
          _, ctype = header_line.split(':', 2)
          ctype = ctype.strip()
          break
        else
          ctype = nil
        end
      }

      id_url = (uri + id_name).to_s
      result = Yadis::DiscoveryResult.new(input_url)
      result.normalized_uri = id_url

      if success
        result.xrds_uri = (uri + result_name).to_s
      end

      result.content_type = ctype
      result.response_text = content
      return [input_url, result]
    end
  end
end
