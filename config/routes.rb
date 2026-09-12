Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API Routes
  namespace :api do
    namespace :v1 do
      post "auth/sync", to: "auth#sync"
      post "auth/update_metadata", to: "auth#update_metadata" # Endpoint de debug para forzar actualización
      patch "users/me", to: "users#update_me"
      post "users/track_usage", to: "users#track_usage"
      resources :products, only: [:index]
      resources :categories, only: [:index]
      resources :health_goals, only: [:index]
      resource :settings, only: [:show]
      resources :evaluation_leads, only: [:create]
      resources :tracking, only: [:index, :create] do
        collection do
          get :prefill
        end
      end
      resources :habits, only: [:index, :create, :destroy] do
        member do
          post :toggle_completion
        end
      end
      resources :recipes, only: [:index, :show], param: :slug do
        collection do
          get :for_me
        end
      end

      namespace :coach_virtual do
        get "profile", to: "profile#show"
        get "body_regions", to: "body_regions#index"

        resources :consultations, only: [:index, :show, :create] do
          member do
            post :close
            post :zone_selections
            post :reflection_answers
          end
        end
      end

      namespace :marketplace do
        resource :cart, only: [:show], controller: "carts" do
          post :clear, to: "carts_clear#create"
        end

        # Endpoints de ítems de carrito usando la ruta /cart/items
        resources :cart_items, path: "cart/items", only: [:create, :update, :destroy]

        get "orders", to: "orders#index"
        post "orders/prepare", to: "orders#prepare"
        post "orders/complete", to: "orders#complete"

        post "checkout/prepare", to: "checkout#prepare"
        post "checkout/webhook", to: "checkout#webhook"
        get "checkout/status", to: "checkout#status"
      end

      namespace :admin do
        namespace :coach_virtual do
          get "profile", to: "profile#show"
          patch "profile", to: "profile#update"
          resources :body_regions
          resources :insights
        end

        resources :users, only: %i[index show update destroy]
        resources :products
        resources :health_goals
        resources :recipes
        resources :orders, only: %i[index show update] do
          member do
            post :check_wompi_status
            post :reconcile_wompi_payment
          end
        end
        resource :settings, only: %i[show update]
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
