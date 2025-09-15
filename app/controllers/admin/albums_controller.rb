class Admin::AlbumsController < Admin::BaseController
  before_action :set_album, only: [:show, :edit, :update, :destroy]

  def index
    @albums = Album.order(created_at: :desc)
  end

  def show; end

  def new
    @album = Album.new
  end

  def create
    @album = Album.new(album_params)
    if @album.save
      redirect_to admin_dashboard_path, notice: "Album créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @album.update(album_params)
      redirect_to admin_dashboard_path, notice: "Album mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @album.destroy
    redirect_to admin_dashboard_path, notice: "Album supprimé."
  end

  private

  def set_album
    @album = Album.find(params[:id])
  end

  def album_params
    params.require(:album).permit(:title, :cover_url, :release_date, :description)
  end
end
