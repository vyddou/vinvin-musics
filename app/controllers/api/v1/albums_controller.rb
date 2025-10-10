# app/controllers/api/v1/albums_controller.rb
class Api::V1::AlbumsController < Api::V1::BaseController
  def index
    albums = Album.order(created_at: :desc)
    render json: albums.map { |a|
      {
        id: a.id,
        title: a.title,
        release_year: a.release_year,
        cover_url: blob_url(a.cover) # (si tu gardes un vieux champ cover_url, ajoute || a.cover_url)
      }
    }
  end

  def show
    a = Album.find(params[:id])
    render json: {
      id: a.id,
      title: a.title,
      release_year: a.release_year,
      cover_url: blob_url(a.cover),
      tracks: a.tracks.map { |t|
        {
          id: t.id,
          title: t.title,
          track_number: t.track_number,
          duration: t.duration,
          audio_url: blob_url(t.audio),
          cover_url: blob_url(a.cover)
        }
      }
    }
  end
end
