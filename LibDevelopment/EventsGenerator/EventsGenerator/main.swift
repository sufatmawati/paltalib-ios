//
//  main.swift
//  EventsGenerator
//
//  Created by Vyacheslav Beltyukov on 01/07/2022.
//

import Foundation
import EventsGeneratorStatic

@discardableResult
func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    print(output)
    
    return output
}

let currentURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

let configFolderURL = currentURL.appendingPathComponent("config")
let configURL = configFolderURL.appendingPathComponent("config.yaml")
let eventsURL = currentURL.appendingPathComponent("Pods/PaltaLibEvents/Sources/Events")

shell("tar -xzvf config.tar.gz")

shell("protoc --swift_out=. config/config.proto --swift_opt=Visibility=Public")

shell("mv -f config/config.pb.swift Pods/PaltaLibEventsTransport/Sources/EventsTransport/config.pb.swift")

shell("chmod -R +w Pods/PaltaLibEvents/Sources/Events/")

try YAMLBasedEventsGenerator(yamlURL: configURL, codeURL: eventsURL).generate()

shell("rm -rf config")
