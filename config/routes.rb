Rails.application.routes.draw do
  devise_for :users
  resources :instagram_wods, only: [:new, :create]
  resources :wodify_wods, only: [:new, :create]
  resources :wods, only: [:index, :show]
  root 'wods#index'
end
