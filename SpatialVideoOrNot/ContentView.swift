//
//  ContentView.swift
//  SpatialVideoOrNot
//
//  Created by Cristian Díaz Peredo on 02.06.24.
//

import AVKit
import PhotosUI
import RealityKit
import SwiftUI
import VideoToolbox

struct ContentView: View {
  @State private var selectedContent: PhotosPickerItem?
  @State private var movie: MaybeSpatialMovie?
  @State private var icon = "video"

  var body: some View {
    VStack {
      if let movie {
        VideoPlayer(player: .init(url: movie.url))
          .overlay(alignment: .topLeading) {
            Image(systemName: icon)
              .padding()
          }
      } else {
        Rectangle()
          .stroke()
      }

      PhotosPicker(selection: $selectedContent, matching: .videos) {
        Label("Library", systemImage: "photo.fill.on.rectangle.fill")
      }
    }
    .padding(60)
    .onChange(of: selectedContent) { _, newValue in
      Task {
        if let maybeSpatialMovie = try await selectedContent?.loadTransferable(
          type: MaybeSpatialMovie.self
        ) {
          movie = maybeSpatialMovie
          if try await maybeSpatialMovie.isSpatial {
            icon = "hexagon"
          } else {
            icon = "video"
          }
        }
      }
    }
  }
}

struct MaybeSpatialMovie: Transferable {
  let url: URL
  var isSpatial: Bool {
    get async throws {
      // MARK: option 1
      // let videoTracks = try await AVAsset(url: received.file.absoluteURL).loadTracks(
      //   withMediaType: .video
      // )
      // for track in videoTracks {
      //   let formatDescriptions = try! await track.load(.formatDescriptions)
      //
      //   for formatDescription in formatDescriptions {
      //     guard
      //       let extensions = CMFormatDescriptionGetExtensions(formatDescription) as? [CFString: Any]
      //     else {
      //       continue
      //     }
      //
      //     if let horizontalFOV = extensions[
      //       kCMFormatDescriptionExtension_HorizontalFieldOfView as CFString
      //     ] as? Double,
      //       horizontalFOV > 0
      //     {
      //       // This is a spatial video track
      //       print("> Spatial video detected")
      //       break
      //     }
      //
      //     // if extensions[kCMFormatDescriptionExtension_HorizontalFieldOfView as CFString] != nil {
      //     //   // This is a spatial video track
      //     //   print(">> Spatial video detected")
      //     //   break
      //     // }
      //   }
      // }

      //MARK: option 2

      let videoTracks = try await AVAsset(url: url).loadTracks(
        withMediaType: .video
      )

      for track in videoTracks {
        let formatDescriptions = try await track.load(.formatDescriptions)
        for formatDescription in formatDescriptions {
          let extensions = CMFormatDescriptionGetExtensions(formatDescription) as? [CFString: Any]
          if extensions?[kCMFormatDescriptionExtension_HasLeftStereoEyeView] as? Int == 1,
            extensions?[kCMFormatDescriptionExtension_HasRightStereoEyeView] as? Int == 1
          {
            print("MV-HEVC video track detected")
            return true
          } else {
            print("Boring video track detected")
            return false
          }
        }
      }

      return false
    }
  }

  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(contentType: .movie) { movie in
      SentTransferredFile(movie.url)
    } importing: { received in
      let copy = URL.documentsDirectory.appending(path: "movie.mp4")

      if FileManager.default.fileExists(atPath: copy.path()) {
        try FileManager.default.removeItem(at: copy)
      }

      try FileManager.default.copyItem(at: received.file, to: copy)
      return Self.init(url: copy)
    }
  }
}

#Preview(windowStyle: .automatic) {
  ContentView()
}
