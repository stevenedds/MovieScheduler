#!/usr/bin/env swift

import Foundation

dump(Process.arguments)

// Properties
var inputFileName = String()
let fileManager = NSFileManager.defaultManager()
let path = fileManager.currentDirectoryPath
let outputFileName = "MovieSchedule.txt"
var inputArray = [String]()
var titles = [String]()
var years = [String]()
var ratings = [String]()
var lengths = [String]()
var daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
let weekdayOpen = 11.0 * 60 + 60
let weekdayClose = 23.0 * 60
let weekendOpen = 10.5 * 60 + 60
let weekendClose = 23.5 * 60
var open = 0.0
var close = 0.0

var schedule = [(title: String, rating: String, length: String, times: [String])]()

// Methods
extension Double {
  var chopped: String {
    return self % 1 == 0 ? String(format: "%.0f", self) : String(self)
  }
}

func roundToFives(x : Double) -> Double {
  return 5 * round(x / 5.0)
}

func amOrpm(isAM: Bool) -> String {
  if isAM == true {
    return "am"
  } else {
    return "pm"
  }
}


func convertTimeFromMinutesToStandard(minutes: Double) -> String {
  var isAM = false
  if minutes < 720 {
    isAM = true
  }
  var hours = floor(minutes/60)
  let minutes = minutes%60
  if hours > 12.0 {
    hours = hours - 12
  }
  
  let hoursString = "\(hours.chopped)"
  var minutesString = ""
  
  if minutes < 10.0 {
    minutesString = "0\(minutes.chopped)"
  } else {
    minutesString = minutes.chopped
  }
  return "\(hoursString):\(minutesString)\(amOrpm(isAM))"
}


for arg in Process.arguments {
  inputFileName = arg
}

do {
  let items = try fileManager.contentsOfDirectoryAtPath(path)
  
  for item in items {
    if inputFileName == item {
      // found file
      print("file found")
    }
  }
} catch {
  // fail
}

let inputFileDirectoryURL = NSURL(fileURLWithPath: path).URLByAppendingPathComponent("\(inputFileName)")
let outputFileDirectoryURL = NSURL(fileURLWithPath: path).URLByAppendingPathComponent("\(outputFileName)")

func formatMovieTimes(times: [String]) -> String {
  var returnTimes = ""
  for time in times {
    returnTimes += "  \(time)\n"
  }
  return returnTimes
}

func giveTheDay(index: Int, numberOfMovies: Int) -> String? {
  if index == 0 {
    return "Monday"
  } else if numberOfMovies == index {
    return "Tuesday"
  } else if index == numberOfMovies*2 {
    return "Wednesday"
  } else if index == numberOfMovies*3 {
    return "Thursday"
  } else if index == numberOfMovies*4 {
    return "Friday"
  } else if index == numberOfMovies*5 {
    return "Saturday"
  } else if index == numberOfMovies*6 {
    return "Sunday"
  } else {
    return nil
  }
}


func writeMovieTimesToFile() {
  do {
    var filetext = ""
    
    let
    movieCount = schedule.count/7
    
    for index in 0..<schedule.count {

      let title = schedule[index].title
      let rating = schedule[index].rating
      let length = schedule[index].length
      let times = formatMovieTimes(schedule[index].times)
      
      if let day = giveTheDay(index, numberOfMovies: movieCount) {
        filetext += "\(day)\n\n"
      }
      
      filetext += "\(title) - Rated \(rating), \(length)\n\(times)\n\n"
    }
    
    
    try filetext.writeToURL(outputFileDirectoryURL, atomically: true, encoding: NSUTF8StringEncoding)
  }
  catch { print("could not write to disk") }
}


func sortInputText() {
  var count = 4
  for _ in 4..<inputArray.count-1 {
    if count % 4 == 0 {
      titles.append(inputArray[count])
    } else if count % 4 == 1 {
      years.append(inputArray[count])
    } else if count % 4 == 2 {
      ratings.append(inputArray[count])
    } else {
      lengths.append(inputArray[count])
    }
    ++count
  }
}


func getMovieTimesAtIndex(index: Int) -> (title: String, rating: String, length: String, times: [String]) {
  var movieTimes = [String]()
  var lastMoveTime = 0.0
  
  let title = titles[index]
  let rating = ratings[index]
  let length = lengths[index]
  let movieLength = convertMovieLengthToDouble(length)
  
  var lastMovieStartTime = 0.0
  
  repeat {
    if lastMoveTime == 0.0 {
      
      lastMoveTime = roundToFives(close - movieLength)
      
      let movieEndTimeDouble = lastMoveTime + movieLength
      
  if movieEndTimeDouble > close {
    lastMoveTime = lastMoveTime-5
      }
      lastMovieStartTime = lastMoveTime
      
      
      
      let movieStartTime = convertTimeFromMinutesToStandard(lastMoveTime)
      let movieEndTime = convertTimeFromMinutesToStandard(lastMoveTime + movieLength)

      movieTimes.insert("\(movieStartTime) - \(movieEndTime)", atIndex: 0)
      
    } else {
      
      lastMoveTime = roundToFives(lastMoveTime - movieLength - 35)
      
      if lastMoveTime + movieLength + 35 > lastMovieStartTime {
        lastMoveTime = lastMoveTime-5
      }

      lastMovieStartTime = lastMoveTime
      
      let movieStartTime = convertTimeFromMinutesToStandard(lastMoveTime)
      let movieEndTime = convertTimeFromMinutesToStandard(lastMoveTime + movieLength)
      
      movieTimes.insert("\(movieStartTime) - \(movieEndTime)", atIndex: 0)
    }
  } while (open) <= (lastMoveTime - movieLength - 35)
  return (title, rating, length, movieTimes)
}

func convertMovieLengthToDouble(length: String) -> Double {
  var hours = 0.0
  var minutes = 0.0
  
  let lengthCleaned = length.stringByReplacingOccurrencesOfString(":", withString: "")

  var count = 0
  for char in lengthCleaned.characters {
    if count == 0 {
      hours = Double("\(char)")! * 60
    } else if count == 1 {
      minutes = Double("\(char)")! * 10
    } else if count == 2 {
      minutes = Double("\(char)")! + minutes
    }
    ++count
  }
  
  return hours+minutes
}


func createSchedule() -> [(title: String, rating: String, length: String, times: [String])] {
  
  var movieSchedule: [(title: String, rating: String, length: String, times: [String])] = []
  
  for day in daysOfWeek {
    switch day {
    case "Monday", "Tuesday", "Wednesday", "Thursday":

      open = weekdayOpen
      close = weekdayClose
      for index in 0..<titles.count {
        movieSchedule.append(getMovieTimesAtIndex(index))
      }
      
    case "Friday", "Saturday", "Sunday":

      open = weekendOpen
      close = weekendClose
      for index in 0..<titles.count {
        movieSchedule.append(getMovieTimesAtIndex(index))
      }
    default: break
    }
  }
  return movieSchedule
}



do {
  var inputFileText = try String(contentsOfURL: inputFileDirectoryURL, encoding: NSASCIIStringEncoding)
  inputFileText = inputFileText.stringByReplacingOccurrencesOfString("\n", withString: ", ")
  inputArray = inputFileText.componentsSeparatedByString(", ")

  sortInputText()
  schedule = createSchedule()
  writeMovieTimesToFile()
  
} catch {
  // fail
}
