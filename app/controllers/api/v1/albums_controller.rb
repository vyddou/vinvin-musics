class Api::V1::AlbumsController < ApplicationController
  def index
  albums = ::Album.all

  if albums.empty?
    render json: []
    return
  end

  albums_data = albums.map do |album| # map transforme chaque album en hash JSON
    {
      id: album.id,
      title: album.title,
      description: album.description,
      cover_url: album.cover_url,
      tracks: album.tracks.map do |track|  # map transforme chaque piste en hash JSON
        {
          id: track.id,
          title: track.title,
          track_number: track.track_number,
          audio_file_url: track.audio_file_url
        }
      end
    }
  end

  render json: albums_data
end
end
