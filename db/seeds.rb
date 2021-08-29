return unless File.exist?('tmp/wod_data.json')
wod_data = JSON.parse(IO.read('tmp/wod_data.json'))

is_succeeded = true
Wod.transaction do
  wod_data.each do |attributes|
    wod = Wod.new(
      date: Date.parse(attributes["date"]),
      name: attributes["name"],
      content: attributes["content"],
      box: attributes["box"]
    )
    unless wod.save
      is_succeeded = false
      puts "#{attributes["date"]}のWODの保存に失敗しました"
      puts "#{wod.errors.full_messages}"
      raise ActiveRecord::Rollback
    end
  end
end

ActiveRecord::Base.connection.reset_pk_sequence!("wods")

if is_succeeded
  puts "全てのWODデータの挿入に成功しました。"
end
