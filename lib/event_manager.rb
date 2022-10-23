require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip, levels: 'country', roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_homephone(homephone)
  homephone.gsub!(/[^\w]/, '').to_s

  if homephone.length == 11 && homephone.start_with?('1')
    homephone[1..10]
  elsif homephone.length != 10
    'Please provide a valid phone number to receive mobile alerts.'
  else
    homephone
  end
end

def target_time(reg_date)
  Time.strptime(reg_date, '%M/%d/%y %k:%M').hour
end

def target_day(reg_date)
  Time.strptime(reg_date, '%M/%d/%y %k:%M').strftime('%A')
end

puts 'Event Manager Initialized!'

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  day = target_day(row[:regdate])
  hour = target_time(row[:regdate])
  phone = clean_homephone(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)

  # puts "Most common registration day is #{day}"
  # puts "Most common registration day is #{hour}"
  # puts "#{name} #{phone}"
  # save_thank_you_letter(id, form_letter)
end
