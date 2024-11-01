class WelcomeController < ApplicationController
  def html
    messages = ["Good Morning", "Good Evening", "Good Night"]
    render locals: { messages: messages }
  end
end
