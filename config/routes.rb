namespace :api do
  namespace :v1 do
    resources :genres, only: [:index, :show]
    resources :albums, only: [:index, :show] do
      resources :tracks, only: [:index]
    end
    resources :tracks, only: [:index, :show]
  end
end
