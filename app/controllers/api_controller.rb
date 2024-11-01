class ApiController < ActionController::API
  def plain
    render plain: 'Hello, world!'
  end

  def json
    render json: { message: 'Hello, world!' }
  end
end
