require 'sinatra/base'
require 'json'

class Provider < Sinatra::Base

  get '/provider.json', :provides => 'json' do
    valid_time = Time.parse(params[:valid_date])
    JSON.pretty_generate({
      :test => 'NO',
      :valid_date => DateTime.now,
      :count => 1000
    })
  end

end
