# Lets the Expo web app (any localhost port) call the API from the browser.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins %r{\Ahttp://(localhost|127\.0\.0\.1)(:\d+)?\z}
    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head]
  end
end
