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

  # Public seller profiles
  resources :sellers, only: %i[show]

  # Notifications
  resources :notifications, only: %i[index update destroy] do
    delete :clear_all, on: :collection
  end

  # Products
  resources :products, only: %i[index show new create edit update destroy] do
    resource :like, only: %i[create destroy]
    member do
      delete :delete_chats
    end
  end

  # Conversations & messages
  resources :conversations, only: %i[index show create destroy] do
    resources :messages, only: :create
  end

  # Orders (escrow payment flow)
  resources :orders, only: %i[index new create show] do
    member do
      get :success
      get :cancel
      post :confirm_received
    end
  end

  # Stripe Connect (seller onboarding)
  resource :stripe_account, only: [] do
    get :new
    get :callback
  end

  namespace :admin do
    get 'moderation', to: 'moderation#index'
    patch 'moderation/approve_product/:id', to: 'moderation#approve_product', as: :approve_product_admin_moderation
    resources :moderation, only: [] do
    member do
      patch :approve_product
    end
  end
  end

  match "/webhooks/stripe", to: proc { [ 405, { "Content-Type" => "text/plain" }, [ "Method Not Allowed" ] ] }, via: :get
  post "/webhooks/stripe", to: "stripe_webhooks#create"

  root "products#index"
end
