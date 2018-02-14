Rails.application.routes.draw do
  # get 'pages/contact'
  # get 'pages/about'

  get 'about', to: 'pages#about', as: :about
  get 'contact', to: 'pages#contact', as: :contact

  root to: 'pages#home'
end
