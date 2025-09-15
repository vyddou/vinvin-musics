# Ouvre le DSL des routes de l'application Rails
Rails.application.routes.draw do
  namespace :admin do
    get 'dashboard/index'
  end
  devise_for :users                 # routes Devise (login/logout/inscription)

  # --- Routes HTML publiques ---
  root "pages#home"                 # page d'accueil publique (player accessible)
  get "up" => "rails/health#show"   # endpoint de santé Rails (optionnel)

  # --- Espace Admin (réservé aux admins) ---
  namespace :admin do                       # toutes les routes commencent par /admin
    get "/" => "dashboard#index", as: :dashboard   # /admin -> tableau de bord admin

    # CRUD Albums géré en admin
    resources :albums do
      # création de pistes imbriquées dans un album (new/create)
      resources :tracks, only: [:new, :create]     # /admin/albums/:album_id/tracks/new
    end

    # édition/suppression d'une piste (hors contexte d'album)
    resources :tracks, only: [:edit, :update, :destroy]
  end

  # --- Espace API (public) ---
  namespace :api do                 # préfixe /api
    namespace :v1 do                # préfixe /api/v1
      resources :genres, only: [:index, :show]
      resources :albums, only: [:index, :show] do
        resources :tracks, only: [:index]   # /api/v1/albums/:album_id/tracks
      end
      resources :tracks, only: [:index, :show]
    end
  end
end
