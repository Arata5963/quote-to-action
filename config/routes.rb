Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  resources :photos, only: [:index, :new, :create, :show, :edit, :update]

end
