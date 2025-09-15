class Admin::BaseController < ApplicationController
  # oblige à être connecté (Devise) avant toute action admin
  before_action :authenticate_user!   # ← protège uniquement l'admin
  # oblige à être admin (booléen sur User)
  before_action :require_admin!       # ← redirige si pas admin
end
