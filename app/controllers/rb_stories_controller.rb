include RbCommonHelper

class RbStoriesController < RbApplicationController
  unloadable
  include Cards
  
  def index
    cards = TaskboardCards.new(current_language)
    
    if params[:sprint_id]
      @sprint.stories.each { |story| cards.add(story) }
    else
      Story.product_backlog(@project).each { |story| cards.add(story, false) }
    end
    
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
