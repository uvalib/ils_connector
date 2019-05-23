Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  devise_for :api_users, defaults: {format: :json}, controllers: {sessions: 'api_users/sessions'}

  namespace :v1 do
    resources :lists, path: '/list', only: [] do
      collection do
        get :libraries
        get :locations
      end
    end
    resources :users, only: [:show] do
      member do
        get :checkouts
        get :holds
        get :reserves
      end
    end
    resources :requests, path: '/request', only: [] do
      collection do
        post :renew_all, path: '/renewAll'
        post :renew
        post :hold
      end
    end
    resources :items, only: :show
  end

  namespace :v2 do
    resources :lists, path: '/list', only: [] do
      collection do
        get :libraries
        get :locations
      end
    end
    resources :users, only: [:show] do
      member do
        get :checkouts
        get :holds
        get :reserves
      end
    end
    resources :requests, path: '/request', only: [] do
      collection do
        post :renew_all, path: '/renewAll'
        post :renew
        post :hold
      end
    end
    resources :items, only: [:show]
  end


  # TODO
  namespace :v3 do
    resources :ivy_requests, only: [:create, :index]
  end

  resources :healthcheck, only: [ :index ]
  resources :version, only: [ :index ]

  root controller: :application, action: :landing

end
