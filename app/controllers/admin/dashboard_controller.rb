class Admin::DashboardController < Admin::BaseController
  # hérite des protections admin
  def index
    @albums = Album.order(created_at: :desc).limit(5)  # derniers albums
    @tracks = Track.order(created_at: :desc).limit(5)  # derniers titres
  end
