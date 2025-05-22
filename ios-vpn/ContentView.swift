
import SwiftUI

struct ContentView: View {
    @StateObject private var vpnManager = VPNManager()
    var body: some View {
        VStack {
            Text("VPN Setup Example")
                .font(.title)
                .padding()

            Button("VPNプロファイルをインストール") {
                vpnManager.initVPN()
                vpnManager.setupVPN()
            }
            .padding()
            
            Button("スタート") {
                vpnManager.initVPN()
                vpnManager.startVPNTunnel()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
