import SwiftUI
struct LaunchScreen: View {
    @State private var isAnimating = false
    @State private var opacity = 0.0
    @State private var scale = 0.8
    @StateObject private var versionManager = VersionManager(appID: "1569193139")
    
    // Callback to notify parent when ready to dismiss
    var onLoadingComplete: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Calm background: the brand blue, a little deeper at the bottom (no white blobs).
            Color.theme.themeBlue.ignoresSafeArea()
            LinearGradient(colors: [.clear, .black.opacity(0.22)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            if !versionManager.showUpdateAlert {
                // Normal Launch Screen
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Logo Container with Shadow and Animation
                    ZStack {
                        // Soft gold glow behind the emblem (instead of the white halo), breathing slowly.
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.theme.gold.opacity(0.22), .clear],
                                    center: .center, startRadius: 40, endRadius: 170
                                )
                            )
                            .frame(width: 340, height: 340)
                            .opacity(isAnimating ? 1 : 0.6)
                        
                        // Logo Image
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                    
                    // App Name or Tagline
                    VStack(spacing: 8) {
                        Text("أرغب في عمل توكيل")
                            .font(.setFontSemiBold(size: 30))
                            .foregroundColor(.white)
                            .opacity(opacity)
                        
                        Text("I want to make a power of attorney")
                            .font(.setFont())
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(opacity)
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Loading Indicator
                    VStack(spacing: 16) {
                        // Modern Loading Animation
                        HStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 10, height: 10)
                                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                                    .animation(
                                        Animation.easeInOut(duration: 0.6)
                                            .repeatForever()
                                            .delay(Double(index) * 0.2),
                                        value: isAnimating
                                    )
                            }
                        }
                        .opacity(opacity)
                        
                        Text("جاري التحميل...")
                            .font(.setFont())
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(opacity)
                    }
                    .padding(.bottom, 60)
                }
            }
            
            // Force Update Overlay
            if versionManager.showUpdateAlert {
                UpdateRequiredView {
                    versionManager.openAppStore()
                }
                .transition(.opacity)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            // Start version check
            versionManager.checkVersion()
            
            // Animate the logo
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
            
            // Start background animation
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .onChange(of: versionManager.versionCheckCompleted) { oldValue, newValue in
            if newValue {
                // Notify parent that loading is complete
                onLoadingComplete?()
            }
        }
    }
}

// MARK: - Preview
struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LaunchScreen()
                .previewDisplayName("Gradient Design")
            
           
        }
    }
}
