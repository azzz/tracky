Rails.application.routes.draw do
  root to: 'home#show'
  post 'user_token' => 'user_token#create'
  get '/secret' => 'home#secret'

  resource :users, only: %i[create]
end
