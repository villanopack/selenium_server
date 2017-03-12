Rails.application.routes.draw do
  root to: 'tests#index'
  resources :projects
  resources :tests, only: [:index, :show, :destroy]
  resources :events, only: [:create]

  require 'resque/server'
  mount Resque::Server => '/resque'
  mount ActionCable.server => '/cable'
end
