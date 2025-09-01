module Api
  module V1
    class TracksController < ApplicationController
      protect_from_forgery with: :null_session

      # GET /api/v1/tracks
      # GET /api/v1/albums/:album_id/tracks
      def index
        if params[:album_id]
          album = Album.find(params[:album_id])
          tracks = album.tracks
        else
          tracks = Track.includes(album: :genre).order(:album_id, :track_number)
        end

        render json: tracks.as_json(
          only: [:id, :title, :artist, :duration_seconds, :audio_url, :cover_url, :track_number],
          include: {
            album: {
              only: [:id, :title, :cover_url, :release_year],
              include: { genre: { only: [:id, :name] } }
            }
          }
        )
      end

      # GET /api/v1/tracks/:id
      def show
        track = Track.includes(album: :genre).find(params[:id])
        render json: track.as_json(
          only: [:id, :title, :artist, :duration_seconds, :audio_url, :cover_url, :track_number],
          include: {
            album: {
              only: [:id, :title, :cover_url, :release_year],
              include: { genre: { only: [:id, :name] } }
            }
          }
        )
      end
    end
  end
end
