import NetworkExtension
import Combine

class VPNManager: ObservableObject {
    @Published var manager: NETunnelProviderManager?

    func initVPN() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            self?.manager = managers?.first ?? NETunnelProviderManager()
        }
    }

    func setupVPN() {
        self.manager?.loadFromPreferences { error in
            if let error = error {
                print("Error loading preferences: \(error.localizedDescription)")
                return
            }
            let tunnelProtocol = NETunnelProviderProtocol()
            tunnelProtocol.serverAddress = "localhost"
            tunnelProtocol.providerBundleIdentifier = "com.superhumster.ios-vpn.packettunnel"
            tunnelProtocol.disconnectOnSleep = false
            tunnelProtocol.providerConfiguration = [:]
            
            self.manager?.protocolConfiguration = tunnelProtocol
            self.manager?.localizedDescription = "superhumster-tunnel-test"
            self.manager?.isEnabled = true
            
            self.manager?.saveToPreferences { error in
                if let error = error {
                    print("Error saving preferences: \(error.localizedDescription)")
                } else {
                    print("VPNプロファイルが保存されました")
                }
            }
        }
    }

    func startVPNTunnel() {
        do {
            try self.manager?.connection.startVPNTunnel()
        } catch {
            print("aaa")
        }
    }
}
