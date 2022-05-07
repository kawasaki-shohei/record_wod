class CalendarsController < ApplicationController
  def show
    @logs = Log.eager_load(:wod).where(date: Date.current.beginning_of_month.to_date..Date.current.end_of_month.to_date)
  end
end
