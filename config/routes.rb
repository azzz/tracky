Rails.application.routes.draw do
  root to: 'home#show'
  post 'user_token' => 'user_token#create'
  get '/secret' => 'home#secret'

  resources :users, only: %i[create]
  resources :issues, only: %i[create index update show]
end
