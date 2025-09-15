class Admin::TracksController < Admin::BaseController
  before_action :set_track, only: [:edit, :update, :destroy]
  before_action :set_album, only: [:new, :create]

  def new
    @track = @album.tracks.build
  end

  def create
    @track = @album.tracks.build(track_params)
    if @track.save
      redirect_to edit_admin_album_path(@album), notice: "Titre ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @track.update(track_params)
      redirect_to edit_admin_album_path(@track.album), notice: "Titre mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    album = @track.album
    @track.destroy
    redirect_to edit_admin_album_path(album), notice: "Titre supprimé."
  end

  private

  def set_track
    @track = Track.find(params[:id])
  end

  def set_album
    @album = Album.find(params[:album_id])
  end

  def track_params
    params.require(:track).permit(:title, :audio_url, :duration, :position)
  end
end
