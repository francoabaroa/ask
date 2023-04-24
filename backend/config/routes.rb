Rails.application.routes.draw do
  # Other routes

  namespace :api do
    namespace :v1 do
      post 'questions/ask', to: 'questions#ask'
    end
  end
end