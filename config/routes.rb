Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  defaults format: :json do
    namespace :v4 do
      resources :availability, only: [:show] do
        collection do
          get :list
        end
      end
      resources :users, only: [:show] do
        member do
          match :check_pin, to: 'users#check_pin', via: [:get, :post]
          post :change_pin
          get :checkouts
          get :bills
          get :holds
        end
        collection do
          post :sirsi_staff_login
          post :forgot_password
          post :change_password_with_token
          post :register
          get "activate/:code", to: "users#activate", as: "activate"
        end
      end
      resources :course_reserves, :only => [] do
        collection do
          get :desks
          get :search
          post :validate
        end
      end
      resources :checkouts, path: '/request', only: [] do
        collection do
          post :renew, path: '/renew'
          post :renew_all, path: '/renewAll'
        end
      end
      resources :requests, only: [] do
        collection do
          # creates a hold
          post :hold, action: :create_hold

          # dev-only
          delete 'hold/:id', action: :delete_hold

          # completes transit, checks out item
          post 'fill_hold/:barcode', action: :fill_hold

          # Create a scan request
          post :scan, action: :create_scan

        end
      end

      resources :dibs, :only => [] do
        collection do

          # Sets/clears the DIBS/reserves status for the item
          put 'indibs/:barcode', action: :set_in_dibs
          put 'nodibs/:barcode', action: :set_no_dibs

          # Checks out a dibs item to a user
          # JWT is required for user_id
          post 'checkout', action: :checkout
          post 'checkin', action: :checkin

        end
      end

      resources :metadata, only: [] do
        member do
          post 'update_rights', action: :update_rights
        end
      end

      # Send /v4/healthcheck and /v4/version to the root path
      resources :healthcheck, only: [ :index ], to: "/healthcheck#index"
      resources :version, only: [:index], to: "/version#index"
    end # v4 namespace

    scope host: env_credential(:pda_base_url) do
      post 'orders' => 'external#nil', as: :pda
    end
  end # format to json

  resources :healthcheck, only: [ :index ]
  resources :version, only: [ :index ]

  root controller: :application, action: :landing

end
