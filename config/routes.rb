Rails.application.routes.draw do
  namespace :v1 do
    resources :libraries

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
      end
    end

    resources :items, only: :show
  end
  namespace :v2 do
    resources :libraries
    resources :users



  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

end
