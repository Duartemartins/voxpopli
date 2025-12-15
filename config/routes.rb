Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations" }

  root "timeline#index"
  get "timeline", to: "timeline#index"

  # Builder Directory
  get "directory", to: "directory#index", as: :directory
  get "directory/sitemap", to: "directory#sitemap", as: :directory_sitemap, defaults: { format: :xml }
  get "directory/:username", to: "directory#show", as: :directory_user

  # Invite code entry
  get "join", to: "invites#new", as: :join
  post "join", to: "invites#verify", as: :verify_invite

  resources :posts, only: [ :show, :create, :destroy ] do
    resource :vote, only: [ :create, :destroy ]
  end

  resources :users, param: :username, only: [ :show, :edit, :update ] do
    resource :follow, only: [ :create, :destroy ]
  end

  namespace :settings do
    resource :account, only: [ :show, :destroy ]
    resources :api_keys, only: [ :index, :create, :destroy ]
  end

  namespace :api do
    namespace :v1 do
      resources :posts, only: [ :index, :show, :create, :destroy ] do
        resource :vote, only: [ :create, :destroy ]
      end
      resources :themes, only: [ :index, :show ]
      resource :me, only: [ :show ], controller: "me"
    end
  end

  get "up", to: "rails/health#show", as: :rails_health_check
end
