# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :shell do
  watch(/^([^\/]*)\.rb/) do
    `osascript -e 'display notification "Rebuilding map" with title "Map"'`
    `bundle exec ruby game.rb`
  end
end
