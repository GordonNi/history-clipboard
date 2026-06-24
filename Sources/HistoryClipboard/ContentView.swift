import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject private var store: ClipboardHistoryStore
    @ObservedObject private var settingsStore: AppSettingsStore
    private let onCopyItem: (ClipboardHistoryItem) -> Void
    @State private var searchText = ""
    @State private var copiedItemID: UUID?
    @State private var isShowingClearConfirmation = false
    @State private var isShowingLaunchAtLoginError = false

    init(
        store: ClipboardHistoryStore,
        settingsStore: AppSettingsStore = AppSettingsStore(),
        onCopyItem: @escaping (ClipboardHistoryItem) -> Void = { _ in }
    ) {
        self.store = store
        self.settingsStore = settingsStore
        self.onCopyItem = onCopyItem
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
            Color(red: 0.78, green: 0.91, blue: 1.0)
                .opacity(0.18)

            VStack(spacing: 0) {
                header
                searchBar
                if store.items.isEmpty {
                    emptyState
                } else if visibleItems.isEmpty {
                    noSearchResults
                } else {
                    historyList
                }
                footer
            }
        }
        .frame(width: 390, height: 560)
        .alert("清空全部历史？", isPresented: $isShowingClearConfirmation) {
            Button("取消", role: .cancel) {
            }
            Button("清空", role: .destructive) {
                store.clearAll()
            }
        } message: {
            Text("这会删除所有文字和图片历史，图片文件也会从本机移除。")
        }
        .alert("无法设置开机启动", isPresented: $isShowingLaunchAtLoginError) {
            Button("知道了", role: .cancel) {
            }
        } message: {
            Text("当前调试运行方式可能不支持开机启动。打包成 macOS App 后再试。")
        }
    }

    private var visibleItems: [ClipboardHistoryItem] {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearchText.isEmpty else {
            return store.items
        }

        return store.items.filter {
            $0.type == .text && $0.textContent.localizedCaseInsensitiveContains(trimmedSearchText)
        }
    }

    private var textItemCount: Int {
        store.items.filter { $0.type == .text }.count
    }

    private var imageItemCount: Int {
        store.items.filter { $0.type == .image }.count
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("历史粘贴板")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.20))

            Spacer()

            Button {
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))
            .help("设置")
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))

            TextField("搜索近期复制内容", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(glassBackground(cornerRadius: 8, opacity: 0.44))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 42, weight: .regular))
                .foregroundStyle(Color(red: 0.49, green: 0.72, blue: 0.91))

            Text("还没有复制记录")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.20))

            Text("复制文字或图片后会显示在这里")
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))

            if settingsStore.isRecordingPaused {
                Label("当前已暂停记录", systemImage: "pause.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.30, green: 0.52, blue: 0.70))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(glassBackground(cornerRadius: 8, opacity: 0.38))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var noSearchResults: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(Color(red: 0.49, green: 0.72, blue: 0.91))

            Text("没有找到匹配内容")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.20))

            Text("换个关键词试试")
                .font(.system(size: 14))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(visibleItems) { item in
                    HistoryCard(
                        item: item,
                        image: store.image(for: item),
                        isCopied: copiedItemID == item.id,
                        onCopy: {
                            copy(item)
                        },
                        onTogglePin: {
                            store.togglePin(item)
                        },
                        onDelete: {
                            store.delete(item)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Label("\(textItemCount) 文字 · \(imageItemCount) 图片", systemImage: "rectangle.stack")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))
                    .lineLimit(1)

                Spacer()

                Button("清空") {
                    isShowingClearConfirmation = true
                }
                .buttonStyle(.bordered)

                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                Text("保存")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))

                Picker("保存期限", selection: retentionDaysBinding) {
                    ForEach(AppSettingsStore.allowedRetentionDays, id: \.self) { days in
                        Text("\(days) 天").tag(days)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            HStack(spacing: 14) {
                Toggle(isOn: $settingsStore.isRecordingPaused) {
                    Label("暂停记录", systemImage: settingsStore.isRecordingPaused ? "pause.circle.fill" : "record.circle")
                }
                .toggleStyle(.switch)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(settingsStore.isRecordingPaused ? Color(red: 0.30, green: 0.52, blue: 0.70) : Color(red: 0.42, green: 0.45, blue: 0.50))

                Spacer()

                Toggle(isOn: launchAtLoginBinding) {
                    Label("开机启动", systemImage: "power")
                }
                .toggleStyle(.switch)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            glassBackground(cornerRadius: 0, opacity: 0.36)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color.white.opacity(0.44))
                        .frame(height: 1)
                }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: {
                settingsStore.launchAtLogin
            },
            set: { enabled in
                if !settingsStore.setLaunchAtLogin(enabled) {
                    isShowingLaunchAtLoginError = true
                }
            }
        )
    }

    private var retentionDaysBinding: Binding<Int> {
        Binding(
            get: {
                settingsStore.retentionDays
            },
            set: { days in
                settingsStore.retentionDays = days
                store.cleanupExpired(retentionDays: days)
            }
        )
    }

    private func copy(_ item: ClipboardHistoryItem) {
        onCopyItem(item)
        copiedItemID = item.id

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if copiedItemID == item.id {
                copiedItemID = nil
            }
        }
    }

    private func glassBackground(cornerRadius: CGFloat, opacity: Double) -> some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
            Color.white.opacity(opacity)
            Color(red: 0.78, green: 0.91, blue: 1.0).opacity(0.10)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private struct HistoryCard: View {
    let item: ClipboardHistoryItem
    let image: NSImage?
    let isCopied: Bool
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    @State private var isImageHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Label(item.type == .text ? "文字" : "图片", systemImage: item.type == .text ? "text.quote" : "photo")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 0.30, green: 0.52, blue: 0.70))

                    if item.isPinned {
                        Label("置顶", systemImage: "pin.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(red: 0.30, green: 0.52, blue: 0.70))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onCopy()
                }

                Spacer()

                if isCopied {
                    Label("已复制", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(red: 0.30, green: 0.52, blue: 0.70))
                }

                Text(item.createdAt, style: .time)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onCopy()
                    }

                Button {
                    onTogglePin()
                } label: {
                    Image(systemName: item.isPinned ? "pin.slash" : "pin")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 0.30, green: 0.52, blue: 0.70))
                .help(item.isPinned ? "取消置顶" : "置顶")

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 0.84, green: 0.27, blue: 0.27))
                .help("删除")
            }

            if item.type == .text {
                Text(item.textContent)
                    .font(.system(size: 14))
                    .lineLimit(4)
                    .foregroundStyle(Color(red: 0.12, green: 0.16, blue: 0.20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onCopy()
                    }
            } else if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.54), lineWidth: 1)
                    )
                    .scaleEffect(isImageHovered ? 1.08 : 1.0)
                    .shadow(
                        color: Color(red: 0.22, green: 0.42, blue: 0.58).opacity(isImageHovered ? 0.24 : 0.0),
                        radius: isImageHovered ? 16 : 0,
                        x: 0,
                        y: isImageHovered ? 8 : 0
                    )
                    .zIndex(isImageHovered ? 1 : 0)
                    .animation(.easeOut(duration: 0.16), value: isImageHovered)
                    .onHover { hovering in
                        isImageHovered = hovering
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        onCopy()
                    }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                    Text("图片文件不可用")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 0.42, green: 0.45, blue: 0.50))
                .frame(maxWidth: .infinity, minHeight: 72)
                .contentShape(Rectangle())
                .onTapGesture {
                    onCopy()
                }
            }
        }
        .padding(14)
        .background(glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
        .shadow(color: Color(red: 0.22, green: 0.42, blue: 0.58).opacity(0.10), radius: 10, x: 0, y: 5)
    }

    private var glassBackground: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
            Color.white.opacity(0.46)
            Color(red: 0.78, green: 0.91, blue: 1.0).opacity(item.isPinned ? 0.18 : 0.08)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: .preview)
            .frame(width: 420, height: 520)
    }
}
