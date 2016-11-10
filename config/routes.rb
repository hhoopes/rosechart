Rails.application.routes.draw do
  root to: 'static_pages#welcome'
  post '/', to: 'rosecharts#upload'
  get '/public/downloads/*chart_id', to: 'downloads#download'
end
