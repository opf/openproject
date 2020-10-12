##
# Creates or updates a BCF issue and markup from a work package
module OpenProject::Bim::BcfXml
  class IssueWriter < BaseWriter
    attr_reader :work_package, :issue, :markup_doc, :markup_node

    TOPIC_SEQUENCE = [
      "ReferenceLink",
      "Title",
      "Priority",
      "Index",
      "Labels",
      "CreationDate",
      "CreationAuthor",
      "ModifiedDate",
      "ModifiedAuthor",
      "DueDate",
      "AssignedTo",
      "Stage",
      "Description",
      "BimSnippet",
      "DocumentReference",
      "RelatedTopic"
    ].freeze

    def self.update_from!(work_package)
      writer = new(work_package)
      writer.update

      writer.issue
    end

    def initialize(work_package)
      @work_package = work_package
      @issue = find_or_initialize_issue

      # Create markup document
      super()

      # Remember root markup node for easier access
      @markup_node = markup_doc.at_xpath('/Markup')
    end

    def update
      # update or create topic node
      topic

      # Override all current comments
      replace_comments

      # Override all current Viewpoints
      replace_viewpoints

      # Replace the markup XML
      issue.markup = markup_doc.to_xml(indent: 2)

      # Save issue and potential new associations
      issue.save!
    end

    protected

    def root_node
      :Markup
    end

    ##
    # Get the nokogiri document from the markup xml
    def build_markup_document
      if issue.markup
        Nokogiri::XML issue.markup, &:noblanks
      else
        super
      end
    end

    ##
    # Update the topic node, or create it
    def topic
      topic_node = fetch(markup_node, 'Topic')

      topic_attributes      topic_node

      topic_reference_link  topic_node
      topic_title           topic_node
      topic_priority        topic_node
      topic_creation_date   topic_node
      topic_creation_author topic_node
      topic_modified_date   topic_node
      topic_modified_author topic_node
      topic_due_date        topic_node
      topic_assigned_to     topic_node
      topic_description     topic_node

      enforce_child_order(topic_node, TOPIC_SEQUENCE)
    end

    def enforce_child_order(parent_node, sequence)
      children_by_name = parent_node
        .children
        .select(&:element?)
        .group_by(&:name)

      sequence.reverse.each do |name|
        if children_with_name = children_by_name[name]
          children_with_name.each do |child|
            parent_node.delete child
            prepend_into_or_insert(parent_node, child)
          end
        end
      end
    end

    def prepend_into_or_insert(parent_node, node)
      if first_child = parent_node.children.select(&:element?)&.first
        first_child.previous = node
      else
        node.parent = parent_node
      end
    end

    def topic_attributes(topic_node)
      topic_node['Guid'] = issue.uuid
      topic_node['TopicType'] = work_package.type.name # TODO: Looks wrong to me. Probably better to use original TopicType?
      topic_node['TopicStatus'] = work_package.status.name
    end

    def topic_title(topic_node)
      target = fetch(topic_node, 'Title')
      target.content = work_package.subject
    end

    def topic_creation_date(topic_node)
      target = fetch(topic_node, 'CreationDate')
      target.content = to_bcf_datetime(work_package.created_at)
    end

    def topic_modified_date(topic_node)
      target = fetch(topic_node, 'ModifiedDate')
      target.content = to_bcf_datetime(work_package.updated_at)
    end

    def topic_description(topic_node)
      target = fetch(topic_node, 'Description')
      target.content = work_package.description
    end

    def topic_creation_author(topic_node)
      target = fetch(topic_node, 'CreationAuthor')
      target.content = work_package.author.mail
    end

    def topic_reference_link(topic_node)
      target = fetch(topic_node, 'ReferenceLink')
      target.content = url_helpers.work_package_url(work_package)
    end

    def topic_priority(topic_node)
      if priority = work_package.priority
        target = fetch(topic_node, 'Priority')
        target.content = priority.name
      end
    end

    def topic_assigned_to(topic_node)
      if assignee = work_package.assigned_to
        target = fetch(topic_node, 'AssignedTo')
        target.content = assignee.mail
      end
    end

    def topic_modified_author(topic_node)
      if journal = work_package.journals.select(:user_id).last
        target = fetch(topic_node, 'ModifiedAuthor')
        target.content = journal.user.mail if journal.user_id
      end
    end

    def topic_due_date(topic_node)
      if work_package.due_date
        target = fetch(topic_node, 'DueDate')
        target.content = to_bcf_date(work_package.due_date.to_datetime)
      end
    end

    def replace_comments
      markup_node.xpath('./Comment').remove

      Nokogiri::XML::Builder.with(markup_node, &method(:comments))
    end

    def replace_viewpoints
      markup_node.xpath('./Viewpoints').remove

      Nokogiri::XML::Builder.with(markup_node, &method(:viewpoints))
    end

    ##
    # Render the comments of the work package as XML nodes
    def comments(xml)
      work_package.journals.select(:id, :notes, :user_id, :created_at).map do |journal|
        next if journal.notes.empty?

        # Create BCF comment reference for the journal
        comment = journal.bcf_comment || issue.comments.create(issue_id: issue, journal_id: journal.id)
        comment_node xml, comment.uuid, journal
      end
    end

    ##
    # Create a single comment node
    def comment_node(xml, uuid, journal)
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
          xml.Viewpoint "#{vp.uuid}.xml"
          xml.Snapshot "#{vp.uuid}#{vp.snapshot.extension}"
        end
      end
    end

    ##
    # Find existing issue or create new
    def find_or_initialize_issue
      ::Bim::Bcf::Issue.find_or_initialize_by(work_package: work_package)
    end
  end
end
