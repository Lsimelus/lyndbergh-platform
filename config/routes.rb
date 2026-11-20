Rails.application.routes.draw do
  root "status#index"
  get "forms" => "forms#index"
  get "sign-in" => "sessions#new", as: :sign_in
  get "auth/google_oauth2/callback" => "sessions#create"
  delete "sign-out" => "sessions#destroy", as: :sign_out
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    post "contact-form", to: "contact_messages#create"
    post "feedback", to: "feedback#create"
  end
end
