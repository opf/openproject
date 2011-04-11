class RbStoriesController < RbApplicationController
  unloadable
  include Cards

  def index
    cards = TaskboardCards.new(current_language)

    @sprint.stories(@project).each { |story| cards.add(story) }

    respond_to do |format|
      format.pdf { send_data(cards.pdf.render, :disposition => 'attachment', :type => 'application/pdf') }
    end
  end

  def create
    params['author_id'] = User.current.id
    story = Story.create_and_position(params)
    status = (story.id ? 200 : 400)

    respond_to do |format|
      format.html { render :partial => "story", :object => story, :status => status }
    end
  end

  def update
    story = Story.find(params[:id])
    result = story.update_and_position!(params)
    story.reload
    status = (result ? 200 : 400)

    respond_to do |format|
      format.html { render :partial => "story", :object => story, :status => status }
    end
  end

end
