import SheepChaseCore
import SheepChasePersistence
import SheepChaseRunStore
import SheepChaseUI
import SwiftUI

public struct MapView: View {
    public init(run: RunRecord) {
        self.run = run
    }
    @Environment(RunStore.self) private var store
    @Bindable var run: RunRecord

    @State private var selectedPinID: String?
    @State private var showDMPins = true
    @State private var showAddCustomPin = false
    @State private var zoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero

    private var mapData: ContentPack.MapData? { store.maps.first }

    private var customPins: [RunCustomMapPin] {
        guard let mapData else { return [] }
        return store.customMapPins(for: mapData.id, in: run)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("场景参考")
                            .bookUI(11)
                            .foregroundStyle(.secondary)
                        Text(mapData?.title ?? "树屋地图")
                            .bookUI(28, weight: .semibold)
                        Text("静态地图 + DM 图钉；拖拽平移、按钮缩放；不做网格、token、迷雾或测距。")
                            .bookUI(12)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("显示 DM 图钉", isOn: $showDMPins)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    HStack(spacing: 4) {
                        Button { setZoom(zoom - 0.15) } label: { Image(systemName: "minus.magnifyingglass") }
                            .buttonStyle(.bordered)
                        Button {
                            setZoom(1)
                            offset = .zero
                        } label: {
                            Text("\(Int(zoom * 100))%").bookUI(11, monospaced: true)
                        }
                        .buttonStyle(.bordered)
                        .help("重置缩放和平移")
                        Button { setZoom(zoom + 0.15) } label: { Image(systemName: "plus.magnifyingglass") }
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
                    Text("拖拽地图可平移；百分比按钮重置视图。图钉只存在于 App 内；导出地图时使用干净原图，不烧录 DM 标记。")
                        .bookUI(12)
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
        .sheet(isPresented: $showAddCustomPin) {
            if let mapData {
                CustomMapPinSheet(map: mapData, run: run)
                    .environment(store)
            }
        }
    }

    private var mapCanvas: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                SheepChaseImages.map
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("诺克的树屋宅院地图")
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
                ForEach(customPins) { pin in
                    customPinButton(pin, in: proxy.size)
                }
            }
            .scaleEffect(zoom)
            .offset(
                x: offset.width + dragOffset.width,
                y: offset.height + dragOffset.height
            )
            .gesture(
                DragGesture(minimumDistance: 8)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        offset = clampedOffset(
                            CGSize(
                                width: offset.width + value.translation.width,
                                height: offset.height + value.translation.height
                            ),
                            in: proxy.size
                        )
                    }
            )
            .help("拖拽平移地图")
        }
        .aspectRatio(1280.0 / 736.0, contentMode: .fit)
        .clipped()
    }

    private func setZoom(_ newValue: CGFloat) {
        zoom = min(2.2, max(0.7, newValue))
        offset = .zero
    }

    private func clampedOffset(_ proposed: CGSize, in size: CGSize) -> CGSize {
        let maxX = max(0, size.width * (zoom - 1) / 2)
        let maxY = max(0, size.height * (zoom - 1) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
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
        .accessibilityLabel(pin.label)
        .position(x: size.width * pin.x, y: size.height * pin.y)
        .help(pin.label)
    }

    private func customPinButton(_ pin: RunCustomMapPin, in size: CGSize) -> some View {
        Button {
            selectedPinID = pin.id.uuidString
        } label: {
            Image(systemName: selectedPinID == pin.id.uuidString ? "mappin.circle.fill" : "mappin.circle")
                .font(.system(size: selectedPinID == pin.id.uuidString ? 22 : 17))
                .foregroundStyle(Theme.gold)
                .background(Circle().fill(Theme.paper.opacity(0.9)).frame(width: 22, height: 22))
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .position(x: size.width * CGFloat(pin.x), y: size.height * CGFloat(pin.y))
        .help(pin.label)
    }

    private var pinList: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("图钉")
                    .bookUI(13, weight: .semibold)
                Spacer()
                Button {
                    showAddCustomPin = true
                } label: {
                    Label("自定义", systemImage: "plus")
                        .bookUI(11)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(Theme.red)
            }
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
                                    .bookUI(12, weight: selectedPinID == pin.id ? .semibold : .regular)
                                Spacer()
                            }
                            if selectedPinID == pin.id, let description = pin.description {
                                Text(description)
                                    .bookUI(11)
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
                if !customPins.isEmpty {
                    Text("自定义图钉")
                        .bookUI(11)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    ForEach(customPins) { pin in
                        Button {
                            selectedPinID = pin.id.uuidString
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Theme.gold)
                                    Text(pin.label)
                                        .bookUI(12, weight: selectedPinID == pin.id.uuidString ? .semibold : .regular)
                                    Spacer()
                                }
                                if selectedPinID == pin.id.uuidString, !pin.note.isEmpty {
                                    Text(pin.note)
                                        .bookUI(11)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.deleteCustomMapPin(pin.id, in: run)
                            } label: {
                                Label("删除图钉", systemImage: "trash")
                            }
                        }
                        Divider()
                    }
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
