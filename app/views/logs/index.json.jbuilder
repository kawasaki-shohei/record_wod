kinds =  {
  unset: {
    color: "gray",
  },
  wod: {
    color: "black",
  },
  skill: {
    color: "green",
  },
  strength: {
    color: "blue",
  },
  conditioning: {
    color: "red",
  },
  stretch: {
    color: "orange"
  },
  other: {
    color: "gray",
  }
}
json.array! @logs do |log|
  json.id log.id
  json.url wod_log_path(log.wod, log, format: :js)
  json.title log.wod.name
  json.start log.date
  json.color kinds[log.kind.to_sym][:color]
end
