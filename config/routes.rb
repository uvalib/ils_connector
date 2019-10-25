Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  # Not used - db removed for now
  # devise_for :api_users, defaults: {format: :json}, controllers: {sessions: 'api_users/sessions'}

  defaults format: :xml do
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
          # firehose used the same response for these
          get :checkouts, action: :show
          get :holds, action: :show
          get :reserves, action: :show
          get :check_pin
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
    #namespace :v3 do
    #  resources :ivy_requests, only: [:create, :index]
    #end
  end #format to xml

  defaults format: :json do
    namespace :v4 do
      resources :availability, only: [:show] do
        collection do
          get :list
        end
      end
      resources :users, only: [:show] do
        member do
          get :check_pin
          get :checkouts
        end
      end
      resources :course_reserves, :only => [] do
        collection do
          get :desks
          get :search
        end
      end
    end
  end # format to json

  resources :healthcheck, only: [ :index ]
  resources :version, only: [ :index ]

  root controller: :application, action: :landing

end
