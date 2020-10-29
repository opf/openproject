class SongCell < Cell::ViewModel
  self.view_paths = ["test/dummy/app/cells"]

  include ActionView::Helpers::FormHelper
  include Cell::Erb

  def protect_against_forgery?
  end

  def with_form_tag_and_content_tag
    render
  end

  def with_content_tag_and_content_tag
    render
  end

  def with_content_tag
    render
  end

  def with_block
    render
  end

  def with_capture
    render
  end

  def with_form_tag
    form_tag("/songs") + content_tag(:span) + "</form>"
  end

  def with_link_to
    render
  end

  def with_form_for_block
    render
  end

  def render_in_render
    render
  end

private
  def cap
    "yay, #{with_output_buffer { yield } }"
  end

  def current_page
    capture do
      #[link_to("1", "/1"), link_to("2", "/2")].join("+") # this breaks, too!
      "<b>No current page!<b>"
    end
  end

  def concatting
    content_tag :div do
      # concat content_tag :p, "Concat!"
      # concat "Whoo"
      content_tag(:p, "Concat!") +
      "Whoo"
    end
  end
end
