import SwiftUI
import DarockKit

public struct SUICChatSupportView: View {
    @State var titleInput = ""
    @State var isSending = false
    @State var supportId = ""
    @State var isSupportMainPresented = false
    public var body: some View {
        List {
            Section {
                TextField("标题", text: $titleInput)
            } header: {
                Text("请为你本次请求支持的问题提供一个描述性的标题：")
            }
            Section {
                ZStack {
                    NavigationLink("", isActive: $isSupportMainPresented, destination: { SupportMainView(supportId: $supportId) })
                        .frame(width: 0, height: 0)
                        .hidden()
                    Button(action: {
                        isSending = true
                        let sde = """
                        \(titleInput)
                        State：0
                        Project：Darock Browser
                        """.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
                        DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/cs/new/\(sde)") { respStr, isSuccess in
                            if isSuccess {
                                supportId = respStr
                                isSupportMainPresented = true
                            }
                        }
                    }, label: {
                        if !isSending {
                            Text("请求支持")
                        } else {
                            ProgressView()
                        }
                    })
                    .disabled(isSending)
                }
            } footer: {
                Text("注意，我们仅提供简体中文的在线支持")
            }
        }
        .navigationTitle("请求实时支持")
    }
}
struct SupportMainView: View {
    @Binding var supportId: String
    @Environment(\.dismiss) var dismiss
    @Namespace var mainScrollLastItem
    @State var chatMessages = [SingleChatMessage]()
    @State var sendTextInput = ""
    @State var isSendingTextMsg = false
    @State var mainUpdateLoopTimer: Timer?
    @State var previousCount = 0
    @State var isFinished = false
    @State var isWaitingAccept = true
    @State var isExitTipPresented = false
    let screenBounds = WKInterfaceDevice.current().screenBounds
    var body: some View {
        ScrollViewReader { scrollProxy in
            // Main Chatting
            ScrollView {
                VStack {
                    if !isWaitingAccept {
                        Spacer()
                            .frame(height: 70)
                    } else {
                        Text("正在等待支持回应...")
                            .padding()
                    }
                    if !chatMessages.isEmpty {
                        ForEach(0..<chatMessages.count, id: \.self) { i in
                            VStack {
                                HStack {
                                    if chatMessages[i].sender != "User" {
                                        HStack {
                                            Spacer()
                                                .frame(width: 5)
                                            VStack {
                                                if let ls = chatMessages[from: i - 1]?.sender, ls != chatMessages[i].sender {
                                                    HStack {
                                                        Text(chatMessages[i].sender)
                                                            .font(.system(size: 14))
                                                            .foregroundStyle(Color.gray)
                                                        Spacer()
                                                    }
                                                    .padding(.vertical, -2)
                                                }
                                                HStack {
                                                    Text(chatMessages[i].content)
                                                        .font(.system(size: 16))
                                                        .foregroundStyle(Color.white)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 6)
                                                        .background {
                                                            RoundedCornersView(color: .init(hex: 0x262629), topLeading: 12, topTrailing: 12, bottomLeading: { () -> CGFloat in
                                                                if let nextMsg = chatMessages[from: i + 1] {
                                                                    if nextMsg.sender != "User" {
                                                                        return 12
                                                                    } else {
                                                                        return 0
                                                                    }
                                                                } else {
                                                                    return 0
                                                                }
                                                            }(), bottomTrailing: 12)
                                                        }
                                                    Spacer(minLength: screenBounds.width - 360)
                                                }
                                            }
                                        }
                                    } else {
                                        HStack {
                                            Spacer(minLength: 20)
                                            Text(chatMessages[i].content)
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color.white)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background {
                                                    RoundedCornersView(color: .init(hex: 0x5099F6), topLeading: 12, topTrailing: 12, bottomLeading: 12, bottomTrailing: { () -> CGFloat in
                                                        if let nextMsg = chatMessages[from: i + 1] {
                                                            if nextMsg.sender == "User" {
                                                                return 12
                                                            } else {
                                                                return 0
                                                            }
                                                        } else {
                                                            return 0
                                                        }
                                                    }())
                                                }
                                        }
                                    }
                                }
                                .padding(.vertical, { () -> CGFloat in if let ls = chatMessages[from: i - 1]?.sender, ls == chatMessages[i].sender { return -3 } else { return 0 } }())
                            }
                            .transition(
                                .opacity
                                    .combined(with: .scale(scale: 0.7))
                                    .combined(with: .offset(y: 30))
                            )
                            .onAppear {
                                scrollProxy.scrollTo(mainScrollLastItem)
                            }
                            .onChange(of: chatMessages.count) { _ in
                                withAnimation {
                                    scrollProxy.scrollTo(mainScrollLastItem)
                                }
                            }
                            .id(i)
                        }
                    }
                    Spacer()
                        .frame(height: 20)
                        .id(mainScrollLastItem)
                    if !isFinished {
                        TextField("发送信息", text: $sendTextInput)
                            .opacity(0.0100000002421438702673861521)
                            .background {
                                ZStack {
                                    Capsule()
                                        .stroke(Color(red: 31/255, green: 31/255, blue: 31/255), lineWidth: 2)
                                    HStack {
                                        Text("发送信息")
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                    .padding(.leading)
                                }
                            }
                            .textFieldStyle(.plain)
                            .submitLabel(.send)
                            .onSubmit {
                                if sendTextInput != "" {
                                    let apdenc = """
                                Sender：User
                                Content：\(sendTextInput)
                                Time：\(Date.now.timeIntervalSince1970)
                                """.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
                                    sendTextInput = ""
                                    DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/cs/reply/\(supportId)/\(apdenc)") { respStr, isSuccess in
                                        if isSuccess {
                                            isSendingTextMsg = false
                                            UpdateDatas()
                                        }
                                    }
                                }
                            }
                    } else {
                        Text("本次支持已结束")
                    }
                }
                .animation(.easeOut, value: chatMessages)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    if !isFinished {
                        isExitTipPresented = true
                    } else {
                        dismiss()
                    }
                }, label: {
                    Image(systemName: "escape")
                        .foregroundColor(.red)
                })
            }
        }
        .alert("结束支持？", isPresented: $isExitTipPresented, actions: {
            Button(role: .destructive, action: {
                let apdenc = """
                State：3
                """.base64Encoded().replacingOccurrences(of: "/", with: "{slash}")
                DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/cs/reply/\(supportId)/\(apdenc)") { _, _ in }
                dismiss()
            }, label: {
                Text("结束")
            })
            Button(role: .cancel, action: {
                
            }, label: {
                Text("取消")
            })
        }, message: {
            Text("除非发起新的支持请求，将不能再继续对话")
        })
        .onAppear {
            UpdateDatas()
            if mainUpdateLoopTimer == nil {
                mainUpdateLoopTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                    UpdateDatas()
                }
            }
        }
        .onDisappear {
            mainUpdateLoopTimer?.invalidate()
            mainUpdateLoopTimer = nil
        }
    }
    
    @_transparent
    @_optimize(speed)
    func UpdateDatas(completion: (() -> Void)? = nil) {
        DarockKit.Network.shared.requestString("https://fapi.darock.top:65535/radar/cs/detail/\(supportId)") { respStr, isSuccess in
            if isSuccess {
                let fixedRawData = respStr.apiFixed().replacingOccurrences(of: "\\n", with: "\n")
                let lineSpd = fixedRawData.split(separator: "\n").map { String($0) }
                if !lineSpd.contains("---") {
                    return
                }
                let msgDatas = fixedRawData.split(separator: "---").dropFirst().map { String($0) }
                if msgDatas.count != previousCount {
                    previousCount = msgDatas.count
                    if lineSpd.contains("State：2") || lineSpd.contains("State：3") {
                        isFinished = true
                        return
                    }
                    chatMessages.removeAll()
                    for smsg in msgDatas {
                        if let it = SingleChatMessage(rawString: smsg) {
                            chatMessages.append(it)
                        }
                    }
                }
                
                completion?()
            }
        }
    }
    
    struct RoundedCornersView: View {
        var color: Color
        var topLeading: CGFloat
        var topTrailing: CGFloat
        var bottomLeading: CGFloat
        var bottomTrailing: CGFloat
        var body: some View {
            GeometryReader { geometry in
                Path { path in
                    let w = geometry.size.width
                    let h = geometry.size.height
                    
                    let tr = min(min(self.topTrailing, h/2), w/2)
                    let tl = min(min(self.topLeading, h/2), w/2)
                    let bl = min(min(self.bottomLeading, h/2), w/2)
                    let br = min(min(self.bottomTrailing, h/2), w/2)
                    
                    path.move(to: CGPoint(x: w / 2.0, y: 0))
                    path.addLine(to: CGPoint(x: w - tr, y: 0))
                    path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
                    path.addLine(to: CGPoint(x: w, y: h - br))
                    path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
                    path.addLine(to: CGPoint(x: bl, y: h))
                    path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
                    path.addLine(to: CGPoint(x: 0, y: tl))
                    path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
                }
                .fill(self.color)
            }
        }
    }
}
struct SingleChatMessage: Identifiable, Equatable, Hashable {
    init(sender: String, content: String, time: TimeInterval) {
        self.sender = sender
        self.content = content
        self.time = time
    }
    init?(rawString: String) {
        var tmpContent: String?
        var tmpSender: String?
        var tmpTime: Double?
        for ld in rawString.split(separator: "\n") {
            if ld.hasPrefix("Sender：") {
                tmpSender = String(ld.dropFirst(7))
            } else if ld.hasPrefix("Content：") {
                tmpContent = String(ld.dropFirst(8)).replacingOccurrences(of: "<#NewLine#<", with: "\n")
            } else if ld.hasPrefix("Time："), let dd = Double(String(ld.dropFirst(5))) {
                tmpTime = dd
            }
        }
        if let sd = tmpSender, let ct = tmpContent, let tm = tmpTime {
            self.sender = sd
            self.content = ct
            self.time = tm
        } else {
            return nil
        }
    }
    
    let id = UUID()
    var sender: String
    var content: String
    var time: TimeInterval
    
    @inline(__always)
    static func == (lhs: SingleChatMessage, rhs: SingleChatMessage) -> Bool {
        return (lhs.sender == rhs.sender) && (lhs.content == rhs.content) && (lhs.time == rhs.time)
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(content)
        hasher.combine(sender)
        hasher.combine(time)
    }
    
    @inline(__always)
    func toRawString() -> String {
        return """
        Sender：\(sender)
        Content：\(content)
        Time：\(Date.now.timeIntervalSince1970)
        """
    }
}
