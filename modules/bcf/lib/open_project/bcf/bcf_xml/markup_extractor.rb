##
# Extracts sections of a BCF markup file
# manually. If we want to extract the entire markup,
# this should be turned into a representable/xml decorator

module OpenProject::Bcf::BcfXml
  class MarkupExtractor
    attr_reader :entry
    attr_accessor :markup, :doc

    def initialize(entry)
      @markup = entry.get_input_stream.read
      @doc = Nokogiri::XML markup, nil, 'UTF-8'
    end

    def uuid
      extract_non_empty :@Guid, attribute: true
    end

    def title
      extract_non_empty :Title
    end

    def priority
      extract_non_empty :Priority
    end

    def status
      extract_non_empty :@TopicStatus, attribute: true
    end

    def type
      extract_non_empty :@TopicType, attribute: true
    end

    def description
      extract_non_empty :Description
    end

    def author
      extract_non_empty :CreationAuthor
    end

    def assignee
      extract_non_empty :AssignedTo
    end

    def modified_author
      extract_non_empty :ModifiedAuthor
    end

    def creation_date
      date = extract_non_empty :CreationDate
      Date.iso8601(date) unless date.nil?
    end

    def modified_date
      date = extract_non_empty :ModifiedDate
      Date.iso8601(date) unless date.nil?
    end

    def due_date
      date = extract_non_empty :DueDate
      Date.iso8601(date) unless date.nil?
    rescue ArgumentError
      nil
    end

    def viewpoints
      doc.xpath('/Markup/Viewpoints').map do |node|
        {
          uuid: node['Guid'],
          viewpoint: node.xpath('Viewpoint/text()').to_s,
          snapshot: node.xpath('Snapshot/text()').to_s
        }.with_indifferent_access
      end
    end

    def comments
      doc.xpath('/Markup/Comment').map do |node|
        {
          uuid: node['Guid'],
          date: node.xpath('Date/text()').to_s,
          author: node.xpath('Author/text()').to_s,
          comment: node.xpath('Comment/text()').to_s
        }.with_indifferent_access
      end
    end

    def mail_addresses
      people
        .filter do |person|
          # person value is an email address
          person =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
        end
        .uniq
    end

    def people
      ([assignee, author] + comments.map { |comment| comment[:author] }).filter(&:present?).uniq
    end

    private

    def extract_non_empty(path, prefix: '/Markup/Topic/'.freeze, attribute: false)
      suffix = attribute ? '' : '/text()'.freeze
      path = [prefix, path.to_s, suffix].join('')
      doc.xpath(path).to_s.presence
    end
  end
end
