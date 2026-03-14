Rails.application.routes.draw do
  devise_for :users, skip: [:registrations, :sessions]

  namespace :api do
    namespace :auth do
      post :signup
      post :login
      post :logout
      post :refresh
    end

    resources :workouts, only: [:create, :update, :show] do
      member do
        post :publish
        post :qr
      end
    end

    resources :qr_codes, only: [] do
      collection do
        get :resolve, to: 'qr_codes#resolve'
      end
    end

    get '/qr/:short_id', to: 'qr_codes#resolve', as: :qr_resolve

    resources :sessions, only: [:create, :show] do
      collection do
        get :current
      end
      member do
        post :results
      end
    end

    resources :coaches, only: [] do
      member do
        get :dashboard
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
