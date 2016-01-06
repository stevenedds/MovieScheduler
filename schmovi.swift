#!/usr/bin/env swift

import Foundation

// Properties
struct Hours {
  var open = Double()
  var close = Double()
}

struct Movie {
  var title = String()
  var year = Int()
  var rating = String()
  var length = String()
}

var weekDay = Hours()
weekDay.open  = 11 * 60 + 60
weekDay.close = 23 * 60

var weekEnd = Hours()
weekEnd.open  = 10.5 * 60.0 + 60.0
weekEnd.close = 23.5 * 60

var movies = [Movie]()
let fileManager = NSFileManager.defaultManager()
let path = fileManager.currentDirectoryPath
let scheduleFileName = "MovieSchedule.txt"

// Functions
func firstArgument() -> String {
  let arguments = Process.arguments
  var inputFileName = String()
  var count = 0
  for arg in arguments {
    if count == 1 {
      inputFileName = arg
    } else if count != 0 {
      print("argument '\(arg)' out of range")
    }
    ++count
  }
  return inputFileName
}

func fileFound() -> Bool {
  let directoryItems = try! fileManager.contentsOfDirectoryAtPath(path)
  
  var fileFound = false
  for item in directoryItems {
    if firstArgument() == item {
      fileFound = true
    }
  }
  return fileFound
}

func inputFileText() {

  let inputFileDirectoryURL = NSURL(fileURLWithPath: path).URLByAppendingPathComponent(firstArgument())
  var inputFileText = try! String(contentsOfURL: inputFileDirectoryURL, encoding: NSASCIIStringEncoding)
  inputFileText = inputFileText.stringByReplacingOccurrencesOfString("\n", withString: ", ")
  let inputArray = inputFileText.componentsSeparatedByString(", ")

  var movie = Movie()
  
  
  var count = 4
  for _ in 4..<inputArray.count-1 {
    if count % 4 == 0 {
      movie.title = inputArray[count]
    } else if count % 4 == 1 {
      if let year = Int(inputArray[count]) {
        movie.year = year
      }
    } else if count % 4 == 2 {
      movie.rating = inputArray[count]
    } else {
      movie.length = inputArray[count]
      movies.append(movie)
    }
    ++count
  }
}

extension Double {
  var chopped: String {
    return self % 1 == 0 ? String(format: "%.0f", self) : String(self)
  }
}


func getMovieTimesAtIndex(index: Int, open: Double, close: Double) -> [String] {
  
  func convertHoursToMinutes(time: String) -> Double {
    let time = time.characters.split(":")
      .flatMap { Int(String($0)) }
      .reduce(0) {  $0 * 60 + $1 }
    return Double(time)
  }
  
  func convertTimeFromMinutesToStandard(minutes: Double) -> String {
    var isAM = false
    if minutes < 720 {
      isAM = true
    }
    var hours = floor(minutes/60)
    let minutes = minutes%60
    if hours > 12 {
      hours = hours - 12
    }
    let hoursString = "\(hours.chopped)"
    var minutesString = ""
    
    if minutes < 10 {
      minutesString = "0\(minutes.chopped)"
    } else {
      minutesString = minutes.chopped
    }
    return "\(hoursString):\(minutesString)\(amOrpm(isAM))"
  }
  
  func amOrpm(isAM: Bool) -> String {
    if isAM == true {
      return "am"
    } else {
      return "pm"
    }
  }
  
  func roundToFives(x : Double) -> Double {
    return 5 * round(x / 5.0)
  }
  
  var movieTimes = [String]()
  var lastMovieTime = 0.0
  let length = convertHoursToMinutes(movies[index].length)
  
  var lastMovieStartTime = 0.0


  repeat {
    if lastMovieTime == 0.0 {
      
      lastMovieTime = roundToFives(close - length)
      
      let movieEndTimeDouble = lastMovieTime + length
      
      if movieEndTimeDouble > close {
        lastMovieTime = lastMovieTime-5
      }
      lastMovieStartTime = lastMovieTime
      
      
      
      let movieStartTime = convertTimeFromMinutesToStandard(lastMovieTime)
      let movieEndTime = convertTimeFromMinutesToStandard(lastMovieTime + length)
      
      movieTimes.insert("\(movieStartTime) - \(movieEndTime)", atIndex: 0)
      
    } else {
      
      lastMovieTime = roundToFives(lastMovieTime - length - 35)
      
      if lastMovieTime + length + 35 > lastMovieStartTime {
        lastMovieTime = lastMovieTime-5
      }
      
      lastMovieStartTime = lastMovieTime
      
      let movieStartTime = convertTimeFromMinutesToStandard(lastMovieTime)
      let movieEndTime = convertTimeFromMinutesToStandard(lastMovieTime + length)
      
      movieTimes.insert("\(movieStartTime) - \(movieEndTime)", atIndex: 0)
    }
  } while (open) <= (lastMovieTime - length - 35)
  return movieTimes
}


func createSchedule() {
  
  var scheduleText = ""
  
  let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  
  func convertArrayToString(times: [String]) -> String {
    var timeString = ""
    for index in 0..<times.count {
      timeString += "  " + times[index] + "\n"
    }
    return timeString
  }

  for day in daysOfWeek {
    
    let movieTitles = movies.map { $0.title }
    let movieRatings = movies.map { $0.rating }
    let movieLengths = movies.map { $0.length }
    
    switch day {
    case "Monday", "Tuesday", "Wednesday", "Thursday":
      scheduleText += day + "\n\n"
      
      for index in 0..<movies.count {
        let movieTimes = getMovieTimesAtIndex(index, open: weekDay.open, close: weekDay.close)
        let title = movieTitles[index]
        let rating = movieRatings[index]
        let length = movieLengths[index]
        scheduleText += "\(title) - Rated \(rating), \(length)\n\(convertArrayToString(movieTimes))\n"
        if index == movies.count-1 {
          scheduleText += "\n"
        }
      }
      
    case "Friday", "Saturday", "Sunday":
      scheduleText += day + "\n\n"
      for index in 0..<movies.count {
        let movieTimes = getMovieTimesAtIndex(index, open: weekEnd.open, close: weekEnd.close)
        let title = movieTitles[index]
        let rating = movieRatings[index]
        let length = movieLengths[index]
        scheduleText += "\(title) - Rated \(rating), \(length)\n\(convertArrayToString(movieTimes))\n"
        if index == movies.count-1 {
          scheduleText += "\n"
        }
      }
      
    default: break
    }
  }
  let scheduleFileDirectoryURL = NSURL(fileURLWithPath: path).URLByAppendingPathComponent("\(scheduleFileName)")
  print("writing 'MovieSchedule.txt'")
  try! scheduleText.writeToURL(scheduleFileDirectoryURL, atomically: true, encoding: NSUTF8StringEncoding)
  print("MovieSchedule complete")

}



// Main
do {
  if fileFound() {
    
    print("'\(firstArgument())' found")

    inputFileText()
    createSchedule()
  } else {
    print("file '\(firstArgument())' not found")
  }
}