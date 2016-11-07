Rails.application.routes.draw do
  root to: 'static_pages#welcome'
  post '/', to: 'rosecharts#upload'
end
