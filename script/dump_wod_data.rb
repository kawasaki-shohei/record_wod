data = Wod.all.order(:date).to_json(only: [:date, :content])
File.open('tmp/wod_data.json', 'w') do |file|
  file << data
end
