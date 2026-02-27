Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Home
  get "home/index", to: "home#index", as: :home_index

  # Authentication
  get    "sign_up",  to: "registrations#new",  as: :sign_up
  post   "sign_up",  to: "registrations#create"
  get    "sign_in",  to: "sessions#new",        as: :sign_in
  post   "sign_in",  to: "sessions#create"
  delete "sign_out", to: "sessions#destroy",    as: :sign_out

  # Profile & security
  resource :profile,  only: %i[show edit update]
  resource :password, only: %i[edit update]

  # Products
  resources :products, only: %i[index show new create edit update destroy] do
    resource :like, only: %i[create destroy]
  end

  root "products#index"
end
