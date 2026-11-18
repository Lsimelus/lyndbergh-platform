Rails.application.routes.draw do
  root "status#index"
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    post "contact-form", to: "contact_messages#create"
    post "feedback", to: "feedback#create"
  end
end
