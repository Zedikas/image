import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var output: UIImage?
    @State private var errorMessage: String?
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        if let output {
                            Image(uiImage: output)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            ContentUnavailableView(
                                "Choose an Image",
                                systemImage: "photo",
                                description: Text("Import a photo to process it with ImageMagick.")
                            )
                        }
                    }
                    .frame(maxHeight: 420)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .onChange(of: selectedItem) {
                        Task {
                            guard let data = try? await selectedItem?.loadTransferable(type: Data.self),
                                  let uiImage = UIImage(data: data) else { return }
                            image = uiImage
                            output = nil
                            errorMessage = nil
                        }
                    }

                    Button {
                        processImage()
                    } label: {
                        Label(isProcessing ? "Processing…" : "Run ImageMagick", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(image == nil || isProcessing)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    Text("ImageMagick \(IMBridge.version())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("ImageMagick")
        }
    }

    private func processImage() {
        guard let image else { return }
        isProcessing = true
        errorMessage = nil

        guard let sourceData = image.pngData() else {
            errorMessage = "Could not encode the source image."
            isProcessing = false
            return
        }

        Task.detached {
            do {
                guard let sourceImage = UIImage(data: sourceData) else {
                    throw IMBridgeError.cannotCreateCGImage
                }
                let result = try IMBridge.resizeAndSharpen(image: sourceImage, width: 1600)
                await MainActor.run {
                    output = result
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
}
