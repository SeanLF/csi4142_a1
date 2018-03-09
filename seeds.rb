require 'csv'
require 'rails'
require 'active_record'
require 'activerecord-import'

def parse_data
    dates = {}
    locations = {}
    shapes = {}
    facts = []

    time_duration = []
   
    # DateTime reported,	City,	State,	Shape,	Duration,	Summary,	Date Posted
    csv = CSV.foreach('/Users/sean/Downloads/nuforcScrape.csv') do |row|
        next if row[0].empty? or row[0].nil?
        # date and time parsing
        datetime = DateTime.parse(row[0])
        date = datetime.to_date
        time = datetime.strftime('%H:%M')

        # get date key
        dateKey = dates[date]
        if dateKey.nil?
            dateKey = dates.size + 1
            dates[date] = dateKey
        end

        # get location key
        location = [row[1], row[2]]
        locationKey = locations[location]
        if locationKey.nil?
            locationKey = locations.size + 1
            locations[location] = locationKey
        end

        # get shape key
        shape = row[3]
        shape = (shape.nil? || shape.empty?)? 'unspecified' : shape.downcase
        shapeKey = shapes[shape]
        if shapeKey.nil?
            shapeKey = shapes.size + 1
            shapes[shape] = shapeKey
        end

        # handle inconsistent durations (or use interval type in db)
        duration = row[4]
        if duration.nil?
            duration = 1 # default
        else
            d = duration.to_f # convert to float (to catch 1.x minutes or hours)
            duration = duration.include?('seconds') ? d : (duration.include?('minutes') ? d*60 : d*3600)
            duration = duration.to_i # round to nearest second
        end

        summary = row[5]
        facts << {dateKey: dateKey, locationKey: locationKey, shapeKey: shapeKey, duration: duration, summary: summary}

        # for scatter plot
        time_duration << [time, duration]
    end
    return {dates: dates, locations: locations, shapes: shapes, facts: facts, q7: time_duration}
end

data = parse_data

# Question 7 data
CSV.open('q7.csv', 'w') do |c|
    data[:q7].each do |r|
        c << r
    end
end

# Import to DB; could also be done by exporting to CSV files
db_shapes = []
data[:shapes].each do |s|
    db_shapes << Shape.new({id: s[1], name: s[0]})
end

db_locations = []
data[:locations].each do |l|
    db_locations << Location.new({id: l[1], city: l[0][0], state: l[0][1]})
end

db_dates = []
data[:dates].each do |d|
    db_dates << ReportedDate.new({id: d[1], reported_date: d[0], week: d[0].cweek, month: d[0].month, year: d[0].year, weekend: d[0].on_weekend?})
end

db_facts = []
data[:facts].each do |f|
    db_facts << UfoFact.new({shape_id: f[:shapeKey], reported_date_id: f[:dateKey], location_id: f[:locationKey], duration: f[:duration], summary: f[:summary]})
end

Location.import db_locations
puts "locations imported"
ReportedDate.import db_dates
puts "dates imported"
Shape.import db_shapes
puts "shapes imported"
UfoFact.import db_facts, :validate => false, batch_size: 1500
puts "facts imported\n\n\t\t------\t\tDONE"
