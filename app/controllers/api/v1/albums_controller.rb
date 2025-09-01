module Api
  module V1
    class AlbumsController < ApplicationController
      protect_from_forgery with: :null_session

      # GET /api/v1/albums
      def index
        albums = Album.includes(:genre).order(:id)
        render json: albums.as_json(
          only: [:id, :title, :cover_url, :release_year],
          include: { genre: { only: [:id, :name] } }
        )
      end

      # GET /api/v1/albums/:id
      def show
        album = Album.includes(:genre, :tracks).find(params[:id])
        render json: album.as_json(
          only: [:id, :title, :cover_url, :release_year],
          include: {
            genre: { only: [:id, :name] },
            tracks: {
              only: [:id, :title, :artist, :duration_seconds, :audio_url, :cover_url, :track_number]
            }
          }
        )
      end
    end
  end
end
