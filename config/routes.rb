Rails.application.routes.draw do
  root "status#index"
  get "forms" => "forms#index"
  get "traffic" => "traffic#index"
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    post "contact-form", to: "contact_messages#create"
    post "feedback", to: "feedback#create"
    get "heartbeat", to: "heartbeat#show"
    post "traffic", to: "traffic#create"
  end
end
