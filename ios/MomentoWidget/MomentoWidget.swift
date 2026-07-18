import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), username: "friend", imageUrl: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), username: "friend", imageUrl: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Read from App Group UserDefaults
        // NOTE: Replace "group.com.setlog.momento" with your actual App Group ID
        let userDefaults = UserDefaults(suiteName: "group.com.setlog.momento")
        let username = userDefaults?.string(forKey: "latest_log_username") ?? "No new logs"
        let imageUrlString = userDefaults?.string(forKey: "latest_log_image_url")
        
        let entry = SimpleEntry(date: Date(), username: username, imageUrl: imageUrlString)
        
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let username: String
    let imageUrl: String?
}

struct MomentoWidgetEntryView : View {
    var entry: Provider.Entry
    
    // We fetch the image synchronously here for simplicity,
    // though WidgetKit allows async loading via getTimeline
    var displayImage: UIImage? {
        guard let urlString = entry.imageUrl,
              let url = URL(string: urlString),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }

    var body: some View {
        ZStack {
            Color(red: 255/255, green: 246/255, blue: 238/255) // authCanvas (#FFF6EE)
            
            if let image = displayImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                VStack {
                    Image(systemName: "video.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
                        .opacity(0.2)
                    Text("No Logs")
                        .font(.headline)
                        .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
                        .opacity(0.5)
                }
            }
            
            // Username Overlay
            if entry.imageUrl != nil {
                VStack {
                    Spacer()
                    HStack {
                        Text("@\(entry.username)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
    }
}

@main
struct MomentoWidget: Widget {
    let kind: String = "MomentoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                MomentoWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                MomentoWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Momento Widget")
        .description("See the latest video log from your friends.")
    }
}
