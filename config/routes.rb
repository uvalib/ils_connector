Rails.application.routes.draw do
  namespace :v1 do
    resources :libraries
    resources :users, only: :show
    resources :items, only: :show
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

end
