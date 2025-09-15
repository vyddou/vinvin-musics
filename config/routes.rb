# Ouvre le DSL des routes de l'application Rails
Rails.application.routes.draw do
  devise_for :users
  # --- Routes HTML (existant) ---

   root "pages#home"     # => GET / affiche pages#home

  # Endpoint de santé par défaut Rails 7 (optionnel)
  get "up" => "rails/health#show"

  # --- Espace API ---
  namespace :api do                   # préfixe /api
    namespace :v1 do                  # préfixe /api/v1

      # Genres (variété, rock, …)
      resources :genres, only: [:index, :show]

      # Albums (et leurs pistes imbriquées)
      resources :albums, only: [:index, :show] do
        resources :tracks, only: [:index]   # /api/v1/albums/:album_id/tracks
      end

      # Pistes (listing global + show)
      resources :tracks, only: [:index, :show]
    end
  end
end
