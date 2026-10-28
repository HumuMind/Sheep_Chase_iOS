import SwiftUI

struct MapView: View {
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    @State private var selectedPinID: String?
    @State private var showDMPins = true
    @State private var zoom: CGFloat = 1

    private var mapData: ContentPack.MapData? { store.maps.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("场景参考")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(mapData?.title ?? "树屋地图")
                            .font(.largeTitle.weight(.semibold))
                        Text("静态地图 + DM 图钉；不做网格、token、迷雾或测距。")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("显示 DM 图钉", isOn: $showDMPins)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    HStack(spacing: 4) {
                        Button { zoom = max(0.7, zoom - 0.15) } label: { Image(systemName: "minus.magnifyingglass") }
                            .buttonStyle(.bordered)
                        Button { zoom = 1 } label: { Text("\(Int(zoom * 100))%").font(.caption.monospacedDigit()) }
                            .buttonStyle(.bordered)
                        Button { zoom = min(2.2, zoom + 0.15) } label: { Image(systemName: "plus.magnifyingglass") }
                            .buttonStyle(.bordered)
                    }
                }

                HStack(alignment: .top, spacing: 14) {
                    mapCanvas
                        .frame(maxWidth: .infinity)
                    pinList
                        .frame(width: 250)
                }

                GroupBox("地图说明") {
                    Text("图钉只存在于 App 内；导出地图时使用干净原图，不烧录 DM 标记。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)
                }
            }
            .padding(24)
            .frame(maxWidth: 980, alignment: .leading)
            .readingPage()
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var mapCanvas: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Image("Map")
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Theme.line, lineWidth: 1)
                    )

                if let mapData {
                    ForEach(mapData.pins.filter { showDMPins || !$0.dmOnly }) { pin in
                        pinButton(pin, in: proxy.size)
                    }
                }
            }
            .scaleEffect(zoom)
        }
        .aspectRatio(1280.0 / 736.0, contentMode: .fit)
        .clipped()
    }

    private func pinButton(_ pin: ContentPack.MapData.Pin, in size: CGSize) -> some View {
        Button {
            selectedPinID = pin.id
        } label: {
            Image(systemName: pin.id == selectedPinID ? "mappin.circle.fill" : "mappin.circle")
                .font(.system(size: pin.id == selectedPinID ? 22 : 17))
                .foregroundStyle(pin.dmOnly ? Theme.red : Theme.green)
                .background(Circle().fill(Theme.paper.opacity(0.85)).frame(width: 22, height: 22))
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .position(x: size.width * pin.x, y: size.height * pin.y)
        .help(pin.label)
    }

    private var pinList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("图钉")
                .font(.headline)
            if let mapData {
                ForEach(mapData.pins.filter { showDMPins || !$0.dmOnly }) { pin in
                    Button {
                        selectedPinID = pin.id
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Image(systemName: pin.dmOnly ? "lock.fill" : "circle.fill")
                                    .font(.system(size: 7))
                                    .foregroundStyle(pin.dmOnly ? Theme.red : Theme.green)
                                Text(pin.label)
                                    .font(.callout.weight(selectedPinID == pin.id ? .semibold : .regular))
                                Spacer()
                            }
                            if selectedPinID == pin.id, let description = pin.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(pin.dmOnly ? "DM-only 图钉" : "玩家可见图钉")
                    Divider()
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7).stroke(Theme.line, lineWidth: 1)
        )
    }
}
