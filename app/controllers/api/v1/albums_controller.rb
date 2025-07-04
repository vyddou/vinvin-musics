class Api::V1::AlbumsController < ApplicationController
  def index
    # On précise ::Album pour chercher à la racine d
    @albums = ::Album.includes(:tracks)
    render json: @albums, include: :tracks
  end
end
