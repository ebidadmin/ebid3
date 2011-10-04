Ebid::Application.routes.draw do

  resources :messages do
    get :show_fields, :on => :collection
    get :cancel, :on => :collection
  end

  resources :diffs, :only => [:index, :show, :create] do
    get :summary, :on => :collection
  end

  resources :line_items do
    put :change, :on => :member
    get :show_fields, :on => :member
    get :rationalize, :on => :collection
    put :do_rationalization, :on => :collection
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
        get :edit_vehicle
        get :attach_photos
        get :print
        get :put_online
        get :reveal_bids
        get :relist
        get :reactivate
      end
      collection do
        get :duplicates
      end
   end
  end
      
  get 'cart/add'
  get 'cart/remove'
  post 'cart/clear'
  get 'cart/show_fields'
  put 'cart/edit_item'
  get 'javascripts/dynamic_models'
  get 'javascripts/dynamic_models2'
  get 'javascripts/formtastic_models'

  resources :photos do
    put :attach, :on => :collection
  end
  
  resources :car_parts do
    get :search, :on => :collection
    get :add_more, :on => :collection
  end

  resources :car_variants
  resources :car_models
  resources :car_brands
  resources :companies
  resources :ranks  
  
  match 'admin/dashboard' => 'admin#index', :as => :admin_index, :via => :get
  match 'admin/entries(/:user_id(/:status(/:page)))' => 'admin#entries', :as => :admin_entries, :via => :get
  match 'admin/online(/:page)' => 'admin#online', :as => :admin_online, :via => :get
  match 'admin/bids(/:page(/:brand))' => 'admin#bids', :as => :admin_bids, :via => :get
  match 'admin/orders(/:page)' => 'admin#orders', :as => :admin_orders, :via => :get
  match 'admin/payments(-:buyer)(/:seller(/:page))' => 'admin#payments', :as => :admin_payments, :via => :get
  match 'admin/buyer_fees(/:buyer(/:seller))' => 'admin#buyer_fees', :as => :admin_buyer_fees, :via => :get
  match 'admin/seller_fees(/:page)' => 'admin#seller_fees', :as => :admin_seller_fees, :via => :get
  match 'admin/utilities' => 'admin#utilities', :as => :admin_utilities, :via => :get
  match 'admin/expire_entries' => 'admin#expire_entries', :as => :admin_expire_entries, :via => :get
  get 'admin/cleanup'
  put 'admin/change_status'
  get 'admin/update_perf_ratios'
  get 'admin/overdue_reminder'

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
  match 'buyer/fees_print(/:page)' => 'buyer#fees_print', :as => :buyer_fees_print, :via => :get

  match 'seller/:user_id/main' => 'seller#main', :as => :seller_main, :via => :get
  match 'seller/:user_id/hub/:brand(/page-(:page))' => 'seller#hub', :as => :seller_hub, :via => :get
  match 'seller/show/:id' => 'seller#show', :as => :seller_show, :via => :get
  match 'seller/:user_id/monitor(/:page)' => 'seller#monitor', :as => :seller_monitor, :via => :get
  match 'seller/:user_id/orders(/:page)' => 'seller#orders', :as => :seller_orders, :via => :get
  match 'seller/:user_id/payments(/:page)' => 'seller#payments', :as => :seller_payments, :via => :get
  match 'seller/:user_id/feedback(/:page)' => 'seller#feedback', :as => :seller_feedback, :via => :get
  match 'seller/:user_id/closed(/:page)' => 'seller#closed', :as => :seller_closed, :via => :get
  match 'seller/:user_id/fees(/:page)' => 'seller#fees', :as => :seller_fees, :via => :get
  match 'seller/:user_id/fees_print(/:page)' => 'seller#fees_print', :as => :seller_fees_print, :via => :get
  match 'seller/:user_id/declines(/:buyer)' => 'seller#declines', :as => :seller_declines, :via => :get
  match 'seller/:user_id/archives(/:page)' => 'seller#archives', :as => :seller_archives, :via => :get
  # get 'seller/index'
  
  resources :bids do
    collection do
      post :accept
      post :decline
      post :calc_diff
    end
  end
    
  resources :orders do
    member do
      put :confirm
      put :seller_status
      put :buyer_paid
      get :print
      get :cancel
      put :confirm_cancel
    end
    collection do
      get :auto_paid
    end
    # , :on => :collection
    resources :ratings
  end

  resources :ratings, :only => :index do
    get :auto, :on => :collection
  end
  
  get "site/index"
  get "site/about"
  get "site/xmas"

  root :to => "site#index"

end
