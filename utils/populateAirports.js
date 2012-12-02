var csv   = require('csv');
var path  = require('path');

var Mongolian = require('mongolian')

server    = new Mongolian();
db        = server.db("ostroterra");
airports  = db.collection("airports");

objects = []

csv()
  
  .fromPath(path.join(__dirname,'../fixtures/airports.csv'))
  
  .transform(function(data){
      data.unshift(data.pop());
      return data;
  })
  
  .on('data',function(data,index){
    airportId   = data[1]
    name        = data[2]
    city        = data[3]
    country     = data[4]
    iata        = data[5]
    icao        = data[6]
    lat         = data[7]
    lon         = data[8]
    alt         = data[9]
    timezone    = data[10]

    objects.push({
      'airportId': airportId,
      'name': name,
      'city': city,
      'country': country,
      'iata': iata,
      'icao': icao,
      'lat': lat,
      'lon': lon,
      'alt': alt,
      'timezone': timezone
    })
  })
  
  .on('end',function(count){


    console.log('>> Airports drop')

    airports.drop();
    console.log('>> Airports insert')
    airports.insert(objects);

    console.log('>> END')
  });