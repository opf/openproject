##
# Creates or updates a BCF issue and markup from a work package
module OpenProject::Bim::BcfXml
  class IssueWriter

    attr_reader :work_package, :issue, :markup_doc, :markup_node

    def self.update_from!(work_package)
      writer = new(work_package)
      writer.update

      writer.issue
    end

    def initialize(work_package)
      @work_package = work_package
      @issue = find_or_initialize_issue

      # Read the existing markup XML or build an empty one
      @markup_doc = build_markup_document

      # Remember root markup node for easier access
      @markup_node = @markup_doc.at_xpath('/Markup')
    end

    def update

      # Replace topic node
      replace_topic

      # Override all current comments
      replace_comments

      # Override all current Viewpoints
      replace_viewpoints

      # Replace the markup XML
      issue.markup = markup_doc.to_xml

      # Save issue and potential new associations
      issue.save!
    end

    private

    ##
    # Get the nokogiri document from the markup xml
    def build_markup_document
      if issue.markup
        Nokogiri::XML issue.markup
      else
        build_initial_markup_xml.doc
      end
    end

    ##
    # Initial markup file as basic BCF compliant xml
    def build_initial_markup_xml
      Nokogiri::XML::Builder.new do |xml|
        xml.comment created_by_comment
        xml.Markup "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema"
      end
    end

    ##
    # Replace the topic node, if any
    def replace_topic
      markup_node.xpath('./Topic').remove

      Nokogiri::XML::Builder.with(markup_node) do |xml|
        topic xml
      end
    end

    ##
    # Render the topic of the work package
    def topic(xml)
      xml.Topic "Guid" => issue.uuid,
                "TopicType" => work_package.type.name,
                "TopicStatus" => work_package.status.name do
        xml.Title work_package.subject
        xml.CreationDate to_bcf_datetime(work_package.created_at)
        xml.ModifiedDate to_bcf_datetime(work_package.updated_at)
        xml.Description work_package.description
        xml.CreationAuthor work_package.author.mail
        xml.ReferenceLink url_helpers.work_package_url(work_package)

        if priority = work_package.priority
          xml.Priority priority.name
        end

        if work_package.due_date
          xml.DueDate to_bcf_date(work_package.due_date)
        end

        if journal = work_package.journals.select(:user_id).last
          xml.ModifiedAuthor journal.user.mail if journal.user_id
        end

        if assignee = work_package.assigned_to
          xml.AssignedTo assignee.mail
        end
      end
    end

    def replace_comments
      markup_node.xpath('./Comment').remove

      Nokogiri::XML::Builder.with(markup_node) do |xml|
        comments xml
      end
    end

    def replace_viewpoints
      markup_node.xpath('./Viewpoints').remove

      Nokogiri::XML::Builder.with(markup_node) do |xml|
        viewpoints xml
      end
    end

    ##
    # Render the comments of the work package as XML nodes
    def comments(xml)
      comments = issue.comments.group_by(&:journal_id)
      work_package.journals.select(:id, :notes, :user_id, :created_at).map do |journal|
        next if journal.notes.empty?

        # Create BCF comment reference for the journal
        comment = comments[journal.id]&.first || issue.comments.build(issue_id: issue, journal_id: journal.id)
        comment_node xml, comment.uuid, journal, work_package
      end
    end

    ##
    # Create a single topic node
    def comment_node(xml, uuid, journal, work_package)
      xml.Comment "Guid" => uuid do
        xml.Date to_bcf_datetime(journal.created_at)
        xml.Author journal.user.mail if journal.user_id
        xml.Comment journal.notes
      end
    end

    ##
    # Write the current set of viewpoints
    def viewpoints(xml)
      issue.viewpoints.find_each do |vp|
        xml.Viewpoints "Guid" => vp.uuid do
          xml.Viewpoint vp.viewpoint_name
          xml.Snapshot vp.snapshot.filename
        end
      end
    end

    ##
    #
    def created_by_comment
      " Created by #{Setting.app_title} #{OpenProject::VERSION} at #{Time.now} "
    end

    ##
    # Find existing issue or create new
    def find_or_initialize_issue
      ::Bim::BcfIssue.find_or_initialize_by(work_package: work_package, project_id: work_package.project_id)
    end

    def to_bcf_datetime(date_time)
      date_time.utc.iso8601
    end

    def to_bcf_date(date)
      date.iso8601
    end

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
    end
  end
end
