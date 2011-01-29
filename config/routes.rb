Ebid::Application.routes.draw do

  resources :line_items do
    put :change, :on => :member
  end

  resources :comments

  devise_for :users, :path => :account

  match 'users/:user_id/entries(-:status(/:page))' => 'entries#index', :as => :user_entries, :via => :get
  resources :users do
    resources :profiles
    resources :ratings, :only => :index
    member do
      put :enable
      put :disable
      post :update_role
      delete :destroy_role
    end
    resources :entries, :shallow => true do
      member do
        get :put_online
        get :decide
        get :relist
        get :reactivate
      end
   end
  end
      
  get 'cart/add'
  get 'cart/remove'
  post 'cart/clear'
  get 'cart/show_fields'
  put 'cart/edit_item'
  get 'javascripts/dynamic_models'
  get 'javascripts/formtastic_models'

  get 'photos/add', :as => :add_photo
  delete 'photos/remove', :as => :remove_photo
  
  resources :car_parts do
    get :search, :on => :collection
  end

  resources :car_variants
  resources :car_models
  resources :car_brands
  resources :companies
  resources :ranks  
  
  match 'admin/dashboard' => 'admin#index', :as => :admin_index, :via => :get
  match 'admin/entries(/:user_id(/:page))' => 'admin#entries', :as => :admin_entries, :via => :get
  match 'admin/online(/:page)' => 'admin#online', :as => :admin_online, :via => :get
  match 'admin/bids(/:page)' => 'admin#bids', :as => :admin_bids, :via => :get
  match 'admin/orders(/:page)' => 'admin#orders', :as => :admin_orders, :via => :get
  match 'admin/payments(/:seller(/:page))' => 'admin#payments', :as => :admin_payments, :via => :get
  match 'admin/buyer_fees(/:page)' => 'admin#buyer_fees', :as => :admin_buyer_fees, :via => :get
  match 'admin/supplier_fees(/:page)' => 'admin#supplier_fees', :as => :admin_supplier_fees, :via => :get
  match 'admin/utilities' => 'admin#utilities', :as => :admin_utilities, :via => :get
  match 'admin/expire_entries' => 'admin#expire_entries', :as => :admin_expire_entries, :via => :get

  match 'buyer/:user_id/main' => 'buyer#main', :as => :buyer_main, :via => :get
  match 'buyer/:user_id/pending(/:page)' => 'buyer#pending', :as => :buyer_pending, :via => :get
  match 'buyer/:user_id/online(/:page)' => 'buyer#online', :as => :buyer_online, :via => :get
  match 'buyer/:user_id/results(/:status(/:page))' => 'buyer#results', :as => :buyer_results, :via => :get
  match 'buyer/:user_id/orders(/:seller(/:page))' => 'buyer#orders', :as => :buyer_orders, :via => :get
  match 'buyer/:user_id/payments(/:seller(/:page))' => 'buyer#payments', :as => :buyer_payments, :via => :get
  match 'buyer/:user_id/payments_print(/:seller(/:page))' => 'buyer#payments_print', :as => :buyer_payments_print, :via => :get
  match 'buyer/:user_id/paid(/:seller(/:page))' => 'buyer#paid', :as => :buyer_paid, :via => :get
  match 'buyer/:user_id/closed(/:page)' => 'buyer#closed', :as => :buyer_closed, :via => :get
  match 'buyer/:user_id/fees(/:page)' => 'buyer#fees', :as => :buyer_fees, :via => :get

  match 'seller/:user_id/main' => 'seller#main', :as => :seller_main, :via => :get
  match 'seller/:user_id/hub/:brand(/page-(:page))' => 'seller#hub', :as => :seller_hub, :via => :get
  match 'seller/:user_id/hub/:brand/:id' => 'seller#show', :as => :seller_show, :via => :get
  match 'seller/:user_id/monitor(/:page)' => 'seller#monitor', :as => :seller_monitor, :via => :get
  match 'seller/:user_id/orders(/:page)' => 'seller#orders', :as => :seller_orders, :via => :get
  match 'seller/:user_id/payments(/:page)' => 'seller#payments', :as => :seller_payments, :via => :get
  match 'seller/:user_id/feedback(/:page)' => 'seller#feedback', :as => :seller_feedback, :via => :get
  match 'seller/:user_id/closed(/:page)' => 'seller#closed', :as => :seller_closed, :via => :get
  match 'seller/:user_id/fees(/:page)' => 'seller#fees', :as => :seller_fees, :via => :get

  resources :bids do
    collection do
      post :accept
      post :decline
    end
  end
  
  resources :orders do
    member do
      put :confirm
      put :seller_status
      put :buyer_paid
    end
    resources :ratings
  end

  resources :ratings, :only => :index do
    get :auto, :on => :collection
  end
  
  get "site/index"
  get "site/about"
  get "site/xmas"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "site#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
