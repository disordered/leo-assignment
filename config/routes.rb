Rails.application.routes.draw do
  # Will provide CRUD operations for /images/. Exclude PATCH/PUT as we don't want to allow modification of images
  resources :images, except: :update
end
