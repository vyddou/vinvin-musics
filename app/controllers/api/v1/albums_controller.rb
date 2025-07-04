class Api::V1::AlbumsController < ApplicationController
  def index
    # On précise ::Album pour chercher à la racine d
    @albums = ::Album.includes(:tracks)
    render json: @albums.to_json(
      include: {tracks: { methods: :audio_file_url } },
      methods: :cover_url
    )
  end
end
