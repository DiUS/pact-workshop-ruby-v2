require 'sinatra/base'
require 'json'

class Provider < Sinatra::Base

  get '/provider.json', :provides => 'json' do
    if params[:valid_date].nil?
      [400, '"valid_date is required"']
    else
      begin
        valid_time = Time.parse(params[:valid_date])
        JSON.pretty_generate({
          :test => 'NO',
          :valid_date => DateTime.now,
          :count => 1000
        })
      rescue ArgumentError => e
        [400, "\"\'#{params[:valid_date]}\' is not a date\""]
      end
    end
  end

end
