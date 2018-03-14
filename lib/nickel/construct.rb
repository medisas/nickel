module Nickel
  class Construct
    attr_accessor :comp_start, :comp_end, :found_in
    def initialize(h)
      h.each { |k, v| send("#{k}=", v) }
    end
  end

  class NullConstruct < Construct
  end

  class DateConstruct < Construct
    attr_accessor :date
    def interpret
      { date: date }
    end
  end

  class DateSpanConstruct < Construct
    attr_accessor :start_date, :end_date
  end

  class PhoneNumberConstruct < Construct
    attr_accessor :area_code, :central_office_code, :line_number
  end

  class TimeConstruct < Construct
    attr_accessor :time
    def interpret
      { time: time }
    end
  end

  class TimeSpanConstruct < Construct
    attr_accessor :start_time, :end_time
  end

  class WrapperConstruct < Construct
    attr_accessor :wrapper_type, :wrapper_length
  end

  class RecurrenceConstruct < Construct
    attr_accessor :repeats, :repeats_on

    def interpret
      if [:daily, :altdaily, :threedaily].include?(repeats)
        interpret_daily_variant
      elsif [:weekly, :altweekly, :threeweekly].include?(repeats)
        interpret_weekly_variant
      elsif [:daymonthly, :altdaymonthly, :threedaymonthly].include?(repeats)
        interpret_daymonthly_variant
      elsif [:datemonthly, :altdatemonthly, :threedatemonthly].include?(repeats)
        interpret_datemonthly_variant
      else
        fail StandardError, 'self is an invalid variant, check value of self.repeats'
      end
    end

    def get_interval
      warn '[DEPRECATION] `get_interval` is deprecated.  Please use `interval` instead.'
      interval
    end

    def interval
      if [:daily, :weekly, :daymonthly, :datemonthly].include?(repeats)
        1
      elsif [:altdaily, :altweekly, :altdaymonthly, :altdatemonthly].include?(repeats)
        2
      elsif [:threedaily, :threeweekly, :threedaymonthly, :threedatemonthly].include?(repeats)
        3
      else
        fail StandardError, 'self.repeats is invalid!!'
      end
    end

    private

    def interpret_daily_variant
      hash_for_occ_base = { type: :daily, interval: interval }
      [hash_for_occ_base]
    end

    # repeats_on is an array of day indices. For example,
    # "every monday and wed" will produce repeats_on == [0,2].
    def interpret_weekly_variant
      hash_for_occ_base = { type: :weekly, interval: interval }
      array_of_occurrences = []
      repeats_on.each do |day_of_week|
        array_of_occurrences << hash_for_occ_base.merge(day_of_week: day_of_week)
      end
      array_of_occurrences
    end

    # repeats_on is an array of arrays: Each sub array has the format
    # [week_of_month, day_of_week].  For example,
    # "the first and second sat of every month" will produce
    # repeats_on == [[1,5], [2,5]]
    def interpret_daymonthly_variant
      hash_for_occ_base = { type: :daymonthly, interval: interval }
      array_of_occurrences = []
      repeats_on.each do |on|
        h = { week_of_month: on[0], day_of_week: on[1] }
        array_of_occurrences << hash_for_occ_base.merge(h)
      end
      array_of_occurrences
    end

    # repeats_on is an array of datemonthly indices.  For example,
    # "the 21st and 22nd of every monthy" will produce repeats_on == [21, 22]
    def interpret_datemonthly_variant
      hash_for_occ_base = { type: :datemonthly, interval: interval }
      array_of_occurrences = []
      repeats_on.each do |date_of_month|
        h = { date_of_month: date_of_month }
        array_of_occurrences << hash_for_occ_base.merge(h)
      end
      array_of_occurrences
    end
  end
end
