require 'sqlite3'

dbloc = SQLite3::Database.open "itunes-database/Locations.itdb"
loc_stmt = dbloc.prepare "select item_pid, location from location"
loc_rs = loc_stmt.execute

dblib = SQLite3::Database.open "itunes-database/Library.itdb"
base_stmt = "select title, artist, album, track_number from item"

target_dir = File.join(ENV["HOME"], "lab/ipod-restore/expanded_files")

def slug(s)
  s.gsub("@", "at").gsub(/[^-\w _=.,]+/, '_')
end

loc_rs.each do | item_pid, location|
  lib_stmt = dblib.prepare "#{base_stmt} where pid = #{item_pid} limit 1"
  lib_rs = lib_stmt.execute
  title, artist, album, track_number = lib_rs.first
  puts "title:#{title}, artist:#{artist}, album:#{album}, track_number:#{track_number}, location:#{location}"
  lib_stmt.close
  album = '' if album.nil?
  artist = '' if artist.nil?
  title = '' if title.nil?

  if title.empty?
    puts "skipping: no title: #{location}"
    next
  end
  
  if artist.empty?
    m = /\A(.*?\S.*?) - /.match(title)
    if m
      puts "Possible artist in title:#{title} -- #{m[1]}"
      artist = m[1]
    else
      puts "Assigning to unknown artist title:#{title}"
      artist = "Unknown Artists"
    end
  end
  album.strip!
  artist.strip!
  title.strip!

  # No need to check case cuz I'm on a mac

  artist_slug = slug(artist)
  album_slug = slug(album)
  title_slug = slug(title)

  target_dir2 = File.join(target_dir, artist_slug)
  if !File.exist?(target_dir2)
    puts %Q/@mkdir "#{target_dir2}"/
    system %Q/mkdir "#{target_dir2}"/
  end
  if !album_slug.empty?
    target_dir3 = File.join(target_dir2, album_slug)
    target_path = "#{target_dir3}/#{'%02d' % track_number} - #{title_slug}"
    if !File.exist?(target_dir3)
      puts %Q/@mkdir "#{target_dir3}"/
      system %Q/mkdir "#{target_dir3}"/
    end
  else
    target_dir3 = target_dir2
    target_path = "#{target_dir3}/#{title_slug}"
  end
  puts %Q/@cp #{location} "#{target_path}"/
  system %Q|cp ipod2/iPod_Control/Music/#{location} "#{target_path}"|
end
loc_stmt.close
dblib.close
dbloc.close
  

