Rails.application.routes.draw do
  get 'tokens/create'
  # get 'users/create'
  resources :users
  resources :tokens, only: [:create]
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
