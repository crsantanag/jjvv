Rails.application.routes.draw do
  # Defines the root path route ("/")
  root "pages#index"

  get  "pages/index"
  get  "balance",       to: "pages#balance"
  post "set_year",      to: "pages#set_year"

  devise_for :users, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }

  resources :users, except: [ :new, :create ]  # <-- para no duplicar /users/new (sign_up)

  resources :addresses do
    collection do
      get  :results    # acción que mostrará los datos filtrados
    end
  end

  resources :bills do
    collection do
      post :import
    end
  end

  resources :deposits do
    collection do
      post :import
      get  :results    # acción que mostrará los datos filtrados
    end
  end

  resources :apartments do
    collection do
      post :import
      get  :results    # acción que mostrará los datos filtrados
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
