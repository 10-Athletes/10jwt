Rails.application.routes.draw do
  get 'tokens/create'
  # get 'users/create'
  resources :users
  resources :tokens, only: [:create]
  resources :sports, only: [:create, :show, :index, :update]
  resources :events, only: [:show, :index]

  get 'usersloggedout', to: 'users#index_logged_out'
  get 'userloggedout/:id', to: 'users#show_logged_out'

  get 'password/reset', to: 'password_resets#new'
  post 'password/reset', to: 'password_resets#create'
  get 'password/reset/edit', to: 'password_resets#edit'
  patch 'password/reset/edit', to: 'password_resets#update'
  patch 'password/reset/validate', to: 'password_resets#validate'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
