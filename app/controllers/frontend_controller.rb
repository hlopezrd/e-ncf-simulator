class FrontendController < ApplicationController
  def index
    render file: Rails.root.join("public", "index.html"), layout: false, content_type: "text/html"
  end
end
