import Combine
import SwiftUI

struct DateFormatted: View {
    var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone =     .init(identifier: "America/Indianapolis")
        formatter.locale = locale
        return formatter
    }
    
    var dateComposed: Date {
        var components = DateComponents(year: 2020, month: 10, day: 5, hour: 14, minute: 5)
        components.calendar = .current
        components.timeZone = .init(identifier: "America/Los_Angeles")
        return components.date ?? Date()
    }

    @Environment(\.locale) var locale: Locale
    var body: some View {
        VStack {
            Text(dateComposed, style: .date) + Text(" ") + Text(dateComposed, style: .time)
            Text(dateComposed, formatter: formatter)
            Text(DateFormatter.localizedString(from: dateComposed, dateStyle: .medium, timeStyle: .full))
            Text(formatter.string(from: dateComposed))
            Text("-----")
            Text(Locale.current.identifier)
            Text(locale.identifier)
            Text(getPreferredLocale().identifier)
        }
    }
}

func getPreferredLocale() -> Locale {
    guard let preferredIdentifier = Locale.preferredLanguages.first else {
        return Locale.current
    }
    return Locale(identifier: preferredIdentifier)
}

struct DateFormatted_Previews: PreviewProvider {
    static var previews: some View {
        DateFormatted()
            .environment(\.locale, .init(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier))
        DateFormatted()
            .environment(\.locale, Locale(identifier: "fr"))
    }
}
