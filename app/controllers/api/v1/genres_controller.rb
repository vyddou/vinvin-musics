module Api
  module V1
    class GenresController < ApplicationController
      protect_from_forgery with: :null_session

      # GET /api/v1/genres
      def index
        genres = Genre.order(:name)
        render json: genres.as_json(only: [:id, :name])
      end

      # GET /api/v1/genres/:id
      def show
        genre = Genre.find(params[:id])
        render json: genre.as_json(
          only: [:id, :name],
          include: {
            albums: { only: [:id, :title, :cover_url, :release_year] }
          }
        )
      end
    end
  end
end
