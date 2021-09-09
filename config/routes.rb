Rails.application.routes.draw do
  resources :instagram_wods, only: [:new, :create]
  resources :wodify_wods, only: [:new, :create]
  resources :wods, only: [:index, :new, :create, :show, :edit, :update] do
    resources :logs
  end
  namespace :api, defaults: { format: :json} do
    namespace :v1 do
      post 'fetch_maebashi_wod', to: 'maebashi_wods#create'
      post 'fetch_wod', to: 'fetch_wods#create'
    end
  end
  root 'wods#index'
end
