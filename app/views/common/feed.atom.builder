xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  first_item = @items.first
  first_item_event = (!first_item.nil? && first_item.respond_to?(:data)) ? first_item.data : first_item
  updated_time = (first_item_event.nil?) ? Time.now : first_item_event.event_datetime

  xml.title   truncate_single_line(@title, :length => 100)
  xml.link    "rel" => "self", "href" => url_for(params.merge(:only_path => false))
  xml.link    "rel" => "alternate", "href" => url_for(params.merge(:only_path => false, :format => nil, :key => nil))
  xml.id      url_for(:controller => '/welcome', :only_path => false)
  xml.updated(updated_time.xmlschema)
  xml.author  { xml.name "#{Setting.app_title}" }
  xml.generator(:uri => Redmine::Info.url) { xml.text! Redmine::Info.app_name; }
  @items.each do |item|
    item_event = (not first_item.nil? and first_item.respond_to?(:data)) ? item.data : item

    xml.entry do
      url = url_for(item_event.event_url(:only_path => false))
      if @project
        xml.title truncate_single_line(item_event.event_title, :length => 100)
      else
        xml.title truncate_single_line("#{item.project} - #{item_event.event_title}", :length => 100)
      end
      xml.link "rel" => "alternate", "href" => url
      xml.id url
      xml.updated item_event.event_datetime.xmlschema
      author = item_event.event_author if item_event.respond_to?(:event_author)
      xml.author do
        xml.name(author)
        xml.email(author.mail) if author.is_a?(User) && !author.mail.blank? && !author.pref.hide_mail
      end if author
      xml.content "type" => "html" do
        xml.text! textilizable(item_event, :event_description, :only_path => false)
      end
    end
  end
end
