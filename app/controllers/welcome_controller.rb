class WelcomeController < ApplicationController
  def index
    render plain: 'Hello, world!'
  end

  def json
    render json: { message: 'Hello, world!' }
  end

  def html
    messages = ["Good Morning", "Good Evening", "Good Night"]
    render locals: { messages: messages }
  end
end
