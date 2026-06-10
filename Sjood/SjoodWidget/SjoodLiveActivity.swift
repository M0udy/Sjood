import ActivityKit
import WidgetKit
import SwiftUI

private let gold      = Color(red: 0.83, green: 0.66, blue: 0.26)
private let deepGreen = Color(red: 0.06, green: 0.18, blue: 0.11)

// Prayer clock time (now + minutes), e.g. "5:45 PM" — no minute countdown shown
private func sjoodPrayerClock(_ minutes: Int) -> String {
    let date = Date().addingTimeInterval(TimeInterval(max(0, minutes) * 60))
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: date)
}

// Time-of-day greeting
private func sjoodGreeting() -> String {
    switch Calendar.current.component(.hour, from: Date()) {
    case 0..<5:   return "Assalamu alaikum"
    case 5..<12:  return "Good morning"
    case 12..<17: return "Good afternoon"
    default:      return "Good evening"
    }
}

struct SjoodLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SjoodActivityAttributes.self) { context in
            LockScreenBanner(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
        } dynamicIsland: { context in
            DynamicIsland {

                // Expanded — leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        IslandIcon(state: context.state, size: 26)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(context.state.prayerName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            if !context.state.prayerArabic.isEmpty {
                                Text(context.state.prayerArabic)
                                    .font(.system(size: 11))
                                    .foregroundColor(gold)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.leading, 6)
                }

                // Expanded — trailing
                DynamicIslandExpandedRegion(.trailing) {
                    trailingView(state: context.state)
                        .padding(.trailing, 6)
                }

                // Expanded — bottom
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.mode == "prayer" {
                        Text("Open Sjood · pray · unlock your apps")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.bottom, 4)
                    }
                }

            } compactLeading: {
                IslandIcon(state: context.state, size: 22)
                    .padding(.leading, 2)

            } compactTrailing: {
                compactTrailingView(state: context.state)
                    .padding(.trailing, 2)

            } minimal: {
                IslandIcon(state: context.state, size: 18)
            }
            .keylineTint(gold)
        }
    }

    @ViewBuilder
    private func trailingView(state: SjoodActivityAttributes.ContentState) -> some View {
        switch state.mode {
        case "completed":
            Text("Alhamdulillah")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(gold)
        case "prayer":
            VStack(alignment: .trailing, spacing: 2) {
                Text("Apps locked")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                Text("Pray to unlock")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(gold)
            }
        case "countdown":
            VStack(alignment: .trailing, spacing: 0) {
                Text(sjoodPrayerClock(state.minutesUntilNext))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(gold)
                Text("prayer")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func compactTrailingView(state: SjoodActivityAttributes.ContentState) -> some View {
        switch state.mode {
        case "completed":
            Text("Done ✓")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(gold)
        case "prayer":
            Text(state.prayerName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(gold)
                .lineLimit(1)
        case "countdown":
            Text(sjoodPrayerClock(state.minutesUntilNext))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(gold)
                .lineLimit(1)
        default:
            EmptyView()
        }
    }
}

// ── Icon — uses logo for countdown/onboarding, SF Symbol for prayer/completed
private struct IslandIcon: View {
    let state: SjoodActivityAttributes.ContentState
    let size: CGFloat

    var body: some View {
        switch state.mode {
        case "completed":
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(.green)
        case "prayer":
            Image(systemName: "lock.fill")
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(gold)
        default:
            // Sjood logo — natural aspect ratio, no color multiply
            Image("SjoodLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: size)
        }
    }
}

// ── Lock screen / notification banner
private struct LockScreenBanner: View {
    let state: SjoodActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {

            // Icon — logo for countdown, SF symbol otherwise
            switch state.mode {
            case "completed":
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.green)
                    .frame(width: 52, height: 52)
            case "prayer":
                Image(systemName: "lock.fill")
                    .font(.system(size: 32))
                    .foregroundColor(gold)
                    .frame(width: 52, height: 52)
            default:
                // Logo — natural width, fixed height, no background square
                Image("SjoodLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 40)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(subtitleText)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            if state.mode == "countdown" {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(sjoodPrayerClock(state.minutesUntilNext))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(gold)
                    Text("prayer")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var titleText: String {
        switch state.mode {
        case "completed": return "Alhamdulillah — prayer done"
        case "prayer":    return "\(state.prayerName) · \(state.prayerArabic)"
        case "countdown": return sjoodGreeting()
        default:          return state.prayerName
        }
    }

    private var subtitleText: String {
        switch state.mode {
        case "completed": return "Apps unlocked. JazakAllah khair."
        case "prayer":    return "Apps locked · open Sjood to pray & unlock"
        case "countdown": return "\(state.prayerName) at \(sjoodPrayerClock(state.minutesUntilNext))"
        default:          return state.prayerArabic
        }
    }
}
