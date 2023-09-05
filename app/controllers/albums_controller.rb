class AlbumsController < ApplicationController

    def index
      # Code for listing all albums goes here.
      @albums = Album.all
      render :index
    end
  
    def new
      # Code for new album form goes here.
      @album = Album.new
      render :new
    end
  
    def create
        @album = Album.new(album_params)
        if @album.save
          redirect_to albums_path
        else
          render :new
        end
      end
    
      # Other controller methods go here.
    
      private
        def album_params
          params.require(:album).permit(:name, :genre)
        end
    
    end
  
    def edit
        @album = Album.find(params[:id])
        render :edit
    end
  
    def show
        @album = Album.find(params[:id])
        render :show
    end
  

    def update
        @album= Album.find(params[:id])
        if @album.update(album_params)
          redirect_to albums_path
        else
          render :edit
        end
    end
  
    def destroy
        @album = Album.find(params[:id])
        @album.destroy
        redirect_to albums_path
    end
  
  end